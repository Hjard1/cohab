import os
import uuid
from datetime import datetime, timezone

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models import DocuSealSubmissionRecord

router = APIRouter()

DOCUSEAL_BASE_URL = os.getenv("DOCUSEAL_BASE_URL", "https://api.docuseal.eu")
DOCUSEAL_API_KEY  = os.getenv("DOCUSEAL_API_KEY", "")


class DocuSealSubmitBody(BaseModel):
    pdf_base64: str
    name_a: str
    email_a: str
    name_b: str
    email_b: str
    sig_y: float
    title: str
    household_id: str


class DocuSealSubmitResponse(BaseModel):
    submission_id: str
    slug: str
    signing_url_a: str
    signing_url_b: str


def _headers() -> dict:
    if not DOCUSEAL_API_KEY:
        raise HTTPException(status_code=500, detail="DOCUSEAL_API_KEY is not configured")
    # DocuSeal EU uses X-Auth-Token. Bearer returns 401 on the EU region.
    return {"X-Auth-Token": DOCUSEAL_API_KEY, "Content-Type": "application/json"}


@router.post("/submit", response_model=DocuSealSubmitResponse)
async def submit(body: DocuSealSubmitBody, db: AsyncSession = Depends(get_db)):
    """
    1. Upload PDF to DocuSeal → creates a signable template.
    2. Create submission with both partners as parallel signers.
    3. Track the submission in cohab_docuseal_submissions for webhook isolation.
    4. Return signing URLs.

    Template names are prefixed with [cohab] to keep them visually distinct
    from Samboappen templates on the shared DocuSeal account dashboard.
    """
    headers = _headers()

    # A4 = 595×842 pt. sig_y is measured from the top (UIKit coordinate space).
    sig_fields = [
        {
            "name": f"{body.name_a} Signature",
            "role": "Partner A",
            "type": "signature",
            "required": True,
            "areas": [{"x": 56, "y": body.sig_y, "w": 200, "h": 50, "page": 1}],
        },
        {
            "name": f"{body.name_b} Signature",
            "role": "Partner B",
            "type": "signature",
            "required": True,
            "areas": [{"x": 320, "y": body.sig_y, "w": 200, "h": 50, "page": 1}],
        },
    ]

    async with httpx.AsyncClient(timeout=30.0) as client:
        # ── Step 1: Create PDF template ───────────────────────────────────────
        try:
            template_resp = await client.post(
                f"{DOCUSEAL_BASE_URL}/templates/pdf",
                headers=headers,
                json={
                    "name": body.title,   # already prefixed [cohab] by iOS client
                    "documents": [{"name": body.title, "file": body.pdf_base64, "fields": sig_fields}],
                },
            )
        except httpx.RequestError as e:
            raise HTTPException(status_code=502, detail=f"DocuSeal unreachable: {e}")

        if template_resp.status_code not in (200, 201):
            raise HTTPException(
                status_code=502,
                detail=f"DocuSeal template error {template_resp.status_code}: {template_resp.text}",
            )

        template_id = template_resp.json().get("id")
        if not template_id:
            raise HTTPException(status_code=502, detail="DocuSeal did not return a template id")

        # ── Step 2: Create submission ─────────────────────────────────────────
        try:
            sub_resp = await client.post(
                f"{DOCUSEAL_BASE_URL}/submissions",
                headers=headers,
                json={
                    "template_id": template_id,
                    "send_email": True,
                    "submitters": [
                        {"name": body.name_a, "email": body.email_a, "role": "Partner A", "order": 0},
                        {"name": body.name_b, "email": body.email_b, "role": "Partner B", "order": 0},
                    ],
                    "message": {
                        "subject": f"Agreement ready to sign: {body.title}",
                        "body": (
                            "Hi {{submitter.name}},\n\n"
                            f"{body.name_a} and {body.name_b} have created a shared ownership "
                            "agreement using cohab.\n\n"
                            "Click below to review and sign:\n{{submitter.link}}"
                        ),
                    },
                },
            )
        except httpx.RequestError as e:
            raise HTTPException(status_code=502, detail=f"DocuSeal unreachable: {e}")

        if sub_resp.status_code not in (200, 201):
            raise HTTPException(
                status_code=502,
                detail=f"DocuSeal submission error {sub_resp.status_code}: {sub_resp.text}",
            )

        submitters = sub_resp.json()
        if not isinstance(submitters, list) or len(submitters) < 2:
            raise HTTPException(status_code=502, detail="Unexpected DocuSeal submission response")

        submission_id = str(submitters[0].get("submission_id", ""))
        slug          = submitters[0].get("slug", "")
        url_a         = submitters[0].get("embed_src", "")
        url_b         = submitters[1].get("embed_src", "")

    # ── Step 3: Track submission in local DB (isolation from Samboappen) ──────
    try:
        record = DocuSealSubmissionRecord(
            household_id=uuid.UUID(body.household_id),
            submission_id=submission_id,
            slug=slug,
            status="pending",
            email_a=body.email_a,
            email_b=body.email_b,
        )
        db.add(record)
        await db.commit()
    except Exception:
        # Non-fatal: signing still works even if DB tracking fails
        await db.rollback()

    return DocuSealSubmitResponse(
        submission_id=submission_id,
        slug=slug,
        signing_url_a=url_a,
        signing_url_b=url_b,
    )


@router.post("/webhook")
async def webhook(request: Request, db: AsyncSession = Depends(get_db)):
    """
    Receives DocuSeal submission.completed events.

    ISOLATION STRATEGY: Samboappen also uses the same DocuSeal account and
    receives ALL events on its own webhook endpoint. To prevent cross-
    contamination we only process events where the submission slug exists
    in cohab's own tracking table. Anything else returns 200 and is ignored.
    """
    payload = await request.json()

    event_type = payload.get("event_type")
    if event_type != "submission.completed":
        return {"ok": True, "action": "ignored", "reason": "not submission.completed"}

    submission = payload.get("submission", {})
    slug = submission.get("slug", "")
    submission_id = str(submission.get("id", ""))

    # Check ownership: is this a cohab submission?
    result = await db.execute(
        select(DocuSealSubmissionRecord).where(
            DocuSealSubmissionRecord.slug == slug
        )
    )
    record = result.scalar_one_or_none()

    if not record:
        # Not a cohab submission — could be Samboappen or another app on the account.
        # Return 200 to acknowledge receipt without processing.
        return {"ok": True, "action": "ignored", "reason": "submission not tracked by cohab"}

    # Mark as signed
    record.status = "completed"
    record.completed_at = datetime.now(timezone.utc)
    await db.commit()

    return {"ok": True, "action": "marked_completed", "slug": slug}
