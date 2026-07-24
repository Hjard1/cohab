import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { X509Certificate, X509ChainBuilder } from "npm:@peculiar/x509@1";

/**
 * Grants one extra BankID signing credit after a StoreKit 2 purchase of the
 * consumable `com.hjard.cohab.bankid_extra`.
 *
 * The iOS app buys the consumable with StoreKit, then POSTs the transaction's
 * jwsRepresentation here. This function verifies the JWS signature against
 * Apple's certificate chain (x5c rooted in the pinned Apple Root CA - G3),
 * checks the payload (bundleId, productId, not revoked), records the
 * transactionId in cohab_consumed_transactions (idempotency / replay
 * protection) and only then grants the credit via the service-role-only RPC
 * cohab_add_bankid_credit.
 *
 * Request:  POST with `Authorization: Bearer <supabase user JWT>` and a JSON
 *           body { "jws": "<signed transaction JWS from StoreKit 2>" }.
 * Response: { "ok": true } | { "duplicate": true } | { "error": ... }
 *
 * Environment (all built into Supabase edge functions, no secrets to set):
 *   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
 * The Apple Root CA - G3 certificate is pinned as a code constant below
 * (APPLE_ROOT_CA_G3_DER_B64), downloaded once from
 * https://www.apple.com/certificateauthority/AppleRootCA-G3.cer
 */

const EXPECTED_BUNDLE_ID = "com.hjard.cohab";
const EXPECTED_PRODUCT_ID = "com.hjard.cohab.bankid_extra";

// Apple Root CA - G3 (DER, base64). CN=Apple Root CA - G3, valid 2014–2039.
// Pinned so the x5c chain must terminate in exactly this root.
const APPLE_ROOT_CA_G3_DER_B64 =
  "MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBSb290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtfTjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySrMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gAMGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM6BgD56KyKA==";

function b64urlDecode(input: string): Uint8Array {
  const b64 = input.replace(/-/g, "+").replace(/_/g, "/");
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

interface VerifiedTransaction {
  transactionId: string;
  productId: string;
  environment: string;
}

/**
 * Verifies a StoreKit 2 signed transaction JWS:
 *  1. header alg is ES256 and carries an x5c certificate chain,
 *  2. the chain ends in the pinned Apple Root CA - G3 and every link verifies,
 *  3. the JWS signature verifies with the leaf certificate's public key,
 *  4. the payload matches the expected bundle/product and is not revoked.
 */
async function verifySignedTransaction(jws: string): Promise<VerifiedTransaction> {
  const parts = jws.split(".");
  if (parts.length !== 3) throw new Error("Malformed JWS");
  const [headerB64, payloadB64, signatureB64] = parts;

  const header = JSON.parse(new TextDecoder().decode(b64urlDecode(headerB64)));
  if (header.alg !== "ES256" || !Array.isArray(header.x5c) || header.x5c.length < 2) {
    throw new Error("Unexpected JWS header (alg/x5c)");
  }

  const rootCert = new X509Certificate(APPLE_ROOT_CA_G3_DER_B64);
  const chainCerts = (header.x5c as string[]).map((c) => new X509Certificate(c));
  const leaf = chainCerts[0];

  // Build the issuer chain, seeding the builder with the pinned root and the
  // intermediates from the header.
  const builder = new X509ChainBuilder({
    certificates: [rootCert, ...chainCerts.slice(1)],
  });
  const chain = await builder.build(leaf);

  // The chain must terminate in exactly the pinned Apple root.
  const builtRoot = chain[chain.length - 1];
  if ((await builtRoot.getThumbprint()) !== (await rootCert.getThumbprint())) {
    throw new Error("x5c chain does not terminate in the pinned Apple Root CA - G3");
  }

  // Verify each certificate's signature with its issuer's public key (and
  // that it is currently valid).
  for (let i = 0; i < chain.length - 1; i++) {
    const ok = await chain[i].verify({
      publicKey: chain[i + 1].publicKey,
      date: new Date(),
    });
    if (!ok) throw new Error(`Certificate chain verification failed at index ${i}`);
  }

  // Verify the JWS signature with the leaf certificate's public key (ES256).
  const leafKey = await crypto.subtle.importKey(
    "spki",
    leaf.publicKey.rawData,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["verify"],
  );
  const signingInput = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  const signatureOk = await crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" },
    leafKey,
    b64urlDecode(signatureB64),
    signingInput,
  );
  if (!signatureOk) throw new Error("JWS signature verification failed");

  const payload = JSON.parse(new TextDecoder().decode(b64urlDecode(payloadB64)));

  if (payload.bundleId !== EXPECTED_BUNDLE_ID) {
    throw new Error(`Unexpected bundleId: ${payload.bundleId}`);
  }
  if (payload.productId !== EXPECTED_PRODUCT_ID) {
    throw new Error(`Unexpected productId: ${payload.productId}`);
  }
  if (payload.revocationDate != null || payload.revocationReason != null) {
    throw new Error("Transaction is revoked");
  }
  if (payload.environment !== "Production" && payload.environment !== "Sandbox") {
    throw new Error(`Unexpected environment: ${payload.environment}`);
  }
  if (typeof payload.transactionId !== "string" || payload.transactionId.length === 0) {
    throw new Error("Missing transactionId");
  }

  console.log(
    `Verified transaction ${payload.transactionId} (env: ${payload.environment})`,
  );
  return {
    transactionId: payload.transactionId,
    productId: payload.productId,
    environment: payload.environment,
  };
}

serve(async (req) => {
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { "Content-Type": "application/json" },
    });

  try {
    if (req.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "No authorization header" }, 401);
    }

    // Verify the requesting user via their JWT (same pattern as delete-account).
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const body = await req.json().catch(() => ({}));
    const jws = String(body?.jws ?? "");
    if (!jws) {
      return json({ error: "Missing jws" }, 400);
    }

    let tx: VerifiedTransaction;
    try {
      tx = await verifySignedTransaction(jws);
    } catch (err) {
      console.error("Transaction verification failed:", err);
      return json({ error: "Invalid transaction" }, 400);
    }

    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // Find the user's household BEFORE consuming the transaction, so a user
    // without a household does not burn a paid transactionId.
    const { data: memberships, error: memberError } = await serviceClient
      .from("household_members")
      .select("household_id")
      .eq("user_id", user.id)
      .order("joined_at", { ascending: true })
      .limit(1);
    if (memberError) {
      console.error("household_members lookup failed:", memberError);
      return json({ error: "Household lookup failed" }, 500);
    }
    const householdId = memberships?.[0]?.household_id;
    if (!householdId) {
      return json({ error: "No household for user" }, 400);
    }

    // Replay protection: only grant the credit when the transactionId was
    // successfully recorded (i.e. never seen before).
    const { error: insertError } = await serviceClient
      .from("cohab_consumed_transactions")
      .insert({
        transaction_id: tx.transactionId,
        user_id: user.id,
        product_id: tx.productId,
      });
    if (insertError) {
      if (insertError.code === "23505") {
        // Already consumed — idempotent success, do NOT grant again.
        return json({ duplicate: true });
      }
      console.error("Failed to record transaction:", insertError);
      return json({ error: "Could not record transaction" }, 500);
    }

    // Grant the credit (RPC is service-role only).
    const { error: rpcError } = await serviceClient.rpc("cohab_add_bankid_credit", {
      p_household_id: householdId,
    });
    if (rpcError) {
      console.error(
        `cohab_add_bankid_credit failed for household ${householdId},` +
          ` transaction ${tx.transactionId}:`,
        rpcError,
      );
      return json({ error: "Could not grant credit" }, 500);
    }

    console.log(
      `Granted BankID credit to household ${householdId}` +
        ` (transaction ${tx.transactionId}, env: ${tx.environment})`,
    );
    return json({ ok: true });
  } catch (err) {
    console.error(err);
    return json({ error: String(err) }, 500);
  }
});
