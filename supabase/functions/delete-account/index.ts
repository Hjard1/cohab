import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify the requesting user via their JWT
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Admin client to delete the user (bypasses RLS, uses service role key)
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Delete the user's household data BEFORE deleting the auth user.
    // Deleting the user alone only cascades to profiles + their membership
    // rows, leaving households/assets/contributions/expenses orphaned.
    //
    // Households where the user is the sole member are deleted entirely —
    // assets, contributions, expenses, invites and memberships cascade.
    // Households shared with a partner keep their data for the remaining
    // partner, but are flagged partner_left_at (read-only mode); the
    // departing user's membership row disappears with the user delete below.
    const { data: memberships, error: memberError } = await supabaseAdmin
      .from("household_members")
      .select("household_id")
      .eq("user_id", user.id);
    if (memberError) {
      return new Response(JSON.stringify({ error: memberError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    for (const m of memberships ?? []) {
      const { count, error: countError } = await supabaseAdmin
        .from("household_members")
        .select("user_id", { count: "exact", head: true })
        .eq("household_id", m.household_id);
      if (countError) {
        return new Response(JSON.stringify({ error: countError.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if ((count ?? 0) <= 1) {
        const { error: hhError } = await supabaseAdmin
          .from("households")
          .delete()
          .eq("id", m.household_id);
        if (hhError) {
          return new Response(JSON.stringify({ error: hhError.message }), {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
      } else {
        // Shared household — leave the data for the remaining partner, but
        // flag it so their app shows "partner deleted their account" and
        // switches to read-only (no new assets/contributions/expenses).
        const { error: flagError } = await supabaseAdmin
          .from("households")
          .update({ partner_left_at: new Date().toISOString() })
          .eq("id", m.household_id);
        if (flagError) {
          return new Response(JSON.stringify({ error: flagError.message }), {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
      }
    }

    // Delete user from auth — cascades to profiles and any remaining
    // membership rows via ON DELETE CASCADE
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id);
    if (deleteError) {
      return new Response(JSON.stringify({ error: deleteError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
