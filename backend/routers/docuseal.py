import os
import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

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


class DocuSealSubmitResponse(BaseModel):
    submission_id: str
    slug: str
    signing_url_a: str
    signing_url_b: str


def _headers() -> dict:
    if not DOCUSEAL_API_KEY:
        raise HTTPException(status_code=500, detail="DOCUSEAL_API_KEY is not configured")
    # DocuSeal EU uses X-Auth-Token; docuseal.com accepts Bearer.
    # X-Auth-Token works on both regions.
    return {"X-Auth-Token": DOCUSEAL_API_KEY, "Content-Type": "application/json"}


@router.post("/submit", response_model=DocuSealSubmitResponse)
async def submit(body: DocuSealSubmitBody):
    """
    1. Upload the PDF to DocuSeal to create a signable template.
    2. Create a submission with both partners as submitters.
    3. Return signing URLs for each partner.
    """
    headers = _headers()

    # A4 page is 595×842 points.  sig_y comes from ContractGenerator (origin top-left).
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
        # Step 1: Create template from PDF
        try:
            template_resp = await client.post(
                f"{DOCUSEAL_BASE_URL}/templates/pdf",
                headers=headers,
                json={
                    "name": body.title,
                    "documents": [
                        {
                            "name": body.title,
                            "file": body.pdf_base64,
                            "fields": sig_fields,
                        }
                    ],
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

        # Step 2: Create submission (sends signing emails)
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
                            f"Hi {{{{submitter.name}}}},\n\n"
                            f"{body.name_a} and {body.name_b} have created a shared ownership agreement "
                            f"using cohab.\n\nClick below to review and sign:\n{{{{submitter.link}}}}"
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

        # submitters[0] = Partner A, submitters[1] = Partner B (order=0 means parallel signing)
        submission_id = str(submitters[0].get("submission_id", ""))
        slug = submitters[0].get("slug", "")
        url_a = submitters[0].get("embed_src", "")
        url_b = submitters[1].get("embed_src", "")

        return DocuSealSubmitResponse(
            submission_id=submission_id,
            slug=slug,
            signing_url_a=url_a,
            signing_url_b=url_b,
        )
