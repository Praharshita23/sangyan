from typing import Any

import re

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from gemini_service import analyze_message, analyze_image


# ============================================================
# APP
# ============================================================

app = FastAPI(
    title="Sangyan API",
    version="1.0.0",
    description="AI-powered scam and phishing detection API",
)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# MODELS
# ============================================================

class MessageRequest(BaseModel):
    message: str


class LinkRequest(BaseModel):
    url: str


# ============================================================
# HEALTH
# ============================================================

@app.get("/")
async def root():
    return {
        "status": "ok",
        "message": "Sangyan API is running",
    }


@app.get("/health")
async def health():
    return {
        "status": "healthy",
    }


# ============================================================
# TEXT SCAN
# ============================================================

@app.post("/scan")
async def scan_message(request: MessageRequest):

    message = request.message.strip()

    if not message:
        raise HTTPException(
            status_code=400,
            detail="Message cannot be empty.",
        )

    try:
        result = await analyze_message(message)

        return normalize_result(
            result,
            message,
        )

    except Exception as e:

        print("\n==============================")
        print("TEXT SCAN ERROR")
        print("==============================")
        print(repr(e))
        print("==============================\n")

        raise HTTPException(
            status_code=500,
            detail="Message analysis failed. Please check the backend/Gemini configuration.",
        )


# ============================================================
# IMAGE SCAN
# ============================================================

@app.post("/scan-image")
async def scan_image(
    file: UploadFile = File(...),
):

    if not file.content_type:
        raise HTTPException(
            status_code=400,
            detail="Invalid image.",
        )

    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="Please upload an image file.",
        )

    try:

        image_bytes = await file.read()

        if not image_bytes:
            raise HTTPException(
                status_code=400,
                detail="Image is empty.",
            )

        result = await analyze_image(
            image_bytes,
            file.content_type,
        )

        message = result.get(
            "message",
            "Text extracted from uploaded image.",
        )

        return normalize_result(
            result,
            message,
        )

    except HTTPException:
        raise

    except Exception as e:

        print("\n==============================")
        print("IMAGE SCAN ERROR")
        print("==============================")
        print(repr(e))
        print("==============================\n")

        raise HTTPException(
            status_code=500,
            detail="Image analysis failed. Please check the backend/Gemini configuration.",
        )


# ============================================================
# LINK SCAN
# ============================================================

@app.post("/scan-link")
async def scan_link(request: LinkRequest):

    url = request.url.strip()

    if not url:
        raise HTTPException(
            status_code=400,
            detail="URL cannot be empty.",
        )

    try:
        return analyze_link(url)

    except Exception as e:

        print("\n==============================")
        print("LINK SCAN ERROR")
        print("==============================")
        print(repr(e))
        print("==============================\n")

        raise HTTPException(
            status_code=500,
            detail="Link analysis failed.",
        )


# ============================================================
# LINK ANALYSIS
# ============================================================

def analyze_link(url: str) -> dict[str, Any]:

    normalized_url = url.strip()

    # Add protocol if missing
    if not re.match(
        r"^https?://",
        normalized_url,
        re.IGNORECASE,
    ):
        normalized_url = "https://" + normalized_url

    lower_url = normalized_url.lower()

    reasons = []

    # --------------------------------------------------------
    # IP ADDRESS
    # --------------------------------------------------------

    if re.search(
        r"https?://\d{1,3}(?:\.\d{1,3}){3}",
        lower_url,
    ):
        reasons.append(
            "The link uses an IP address instead of a normal domain."
        )

    # --------------------------------------------------------
    # @ SYMBOL
    # --------------------------------------------------------

    if "@" in lower_url:

        reasons.append(
            "The URL contains an @ symbol, which can hide the real destination."
        )

    # --------------------------------------------------------
    # URL SHORTENERS
    # --------------------------------------------------------

    shorteners = [
        "bit.ly",
        "tinyurl.com",
        "t.co",
        "goo.gl",
        "is.gd",
        "cutt.ly",
        "rb.gy",
        "shorturl.at",
    ]

    for shortener in shorteners:

        if shortener in lower_url:

            reasons.append(
                "The URL uses a URL-shortening service."
            )

            break

    # --------------------------------------------------------
    # SUSPICIOUS KEYWORDS
    # --------------------------------------------------------

    suspicious_words = [
        "verify",
        "verification",
        "login",
        "signin",
        "secure",
        "account",
        "password",
        "passwd",
        "otp",
        "bank",
        "banking",
        "kyc",
        "claim",
        "winner",
        "winning",
        "prize",
        "urgent",
        "refund",
        "payment",
        "wallet",
        "upi",
        "blocked",
        "suspended",
    ]

    found_words = []

    for word in suspicious_words:

        if word in lower_url:
            found_words.append(word)

    if found_words:

        reasons.append(
            "The URL contains potentially suspicious keywords: "
            + ", ".join(found_words)
        )

    # --------------------------------------------------------
    # EXCESSIVE SUBDOMAINS
    # --------------------------------------------------------

    try:

        domain_part = (
            normalized_url
            .split("//", 1)[1]
            .split("/", 1)[0]
            .split(":", 1)[0]
        )

        if domain_part.count(".") >= 4:

            reasons.append(
                "The domain contains an unusually large number of subdomains."
            )

    except Exception:
        pass

    # --------------------------------------------------------
    # VERY LONG URL
    # --------------------------------------------------------

    if len(normalized_url) > 200:

        reasons.append(
            "The URL is unusually long."
        )

    # --------------------------------------------------------
    # RISK CALCULATION
    # --------------------------------------------------------

    reason_count = len(reasons)

    if reason_count >= 2:

        is_scam = True
        risk_level = "High"

        confidence = min(
            0.60 + reason_count * 0.08,
            0.95,
        )

    elif reason_count == 1:

        is_scam = False
        risk_level = "Medium"

        confidence = 0.65

    else:

        is_scam = False
        risk_level = "Low"

        confidence = 0.85

    # --------------------------------------------------------
    # RESPONSE
    # --------------------------------------------------------

    return {
        "message": normalized_url,

        "analysis": (
            "Potentially suspicious indicators were found."
            if reasons
            else
            "No obvious phishing indicators were detected by the basic URL checks."
        ),

        "is_scam": is_scam,

        "scam_type": (
            "Phishing / Suspicious Link"
            if reasons
            else
            "No obvious scam indicators"
        ),

        "risk_level": risk_level,

        "confidence": confidence,

        "category": "Suspicious Links",

        "reasons": reasons,
    }


# ============================================================
# NORMALIZE GEMINI RESPONSE
# ============================================================

def normalize_result(
    result: dict[str, Any],
    fallback_message: str,
) -> dict[str, Any]:

    if not isinstance(result, dict):
        result = {}

    reasons = parse_reasons(
        result.get("reasons", [])
    )

    # If Gemini didn't return reasons,
    # generate them from the analysis text.
    if not reasons:

        reasons = generate_basic_reasons(
            result,
            fallback_message,
        )

    return {

        "message": str(
            result.get(
                "message",
                fallback_message,
            )
        ),

        "analysis": str(
            result.get(
                "analysis",
                "No detailed analysis available.",
            )
        ),

        "is_scam": parse_bool(
            result.get(
                "is_scam",
                False,
            )
        ),

        "scam_type": str(
            result.get(
                "scam_type",
                "Unknown",
            )
        ),

        "risk_level": normalize_risk_level(
            result.get(
                "risk_level",
                "Unknown",
            )
        ),

        "confidence": parse_confidence(
            result.get(
                "confidence",
                0,
            )
        ),

        "category": str(
            result.get(
                "category",
                "Unknown",
            )
        ),

        "reasons": reasons,
    }


# ============================================================
# BOOLEAN PARSER
# ============================================================

def parse_bool(value: Any) -> bool:

    if isinstance(value, bool):
        return value

    if isinstance(value, str):

        return value.strip().lower() in {
            "true",
            "yes",
            "1",
        }

    if isinstance(value, (int, float)):

        return value != 0

    return False


# ============================================================
# CONFIDENCE PARSER
# ============================================================

def parse_confidence(value: Any) -> float:

    try:

        confidence = float(value)

        # Gemini may return 85 instead of 0.85
        if confidence > 1:
            confidence /= 100

        return max(
            0.0,
            min(confidence, 1.0),
        )

    except Exception:

        return 0.0


# ============================================================
# RISK LEVEL
# ============================================================

def normalize_risk_level(value: Any) -> str:

    if value is None:
        return "Unknown"

    value = str(value).strip().lower()

    if value == "high":
        return "High"

    if value == "medium":
        return "Medium"

    if value == "low":
        return "Low"

    return "Unknown"


# ============================================================
# REASONS PARSER
# ============================================================

def parse_reasons(value: Any) -> list[str]:

    if isinstance(value, list):

        return [
            str(item).strip()
            for item in value
            if item is not None
            and str(item).strip()
        ]

    if isinstance(value, str):

        # Support comma-separated reasons
        parts = value.split(",")

        return [
            part.strip()
            for part in parts
            if part.strip()
        ]

    return []


# ============================================================
# BASIC REASON FALLBACK
# ============================================================

def generate_basic_reasons(
    result: dict[str, Any],
    message: str,
) -> list[str]:

    text = message.lower()

    reasons = []

    if "otp" in text:
        reasons.append(
            "The message asks for or mentions an OTP."
        )

    if "pin" in text:
        reasons.append(
            "The message asks for a PIN."
        )

    if "password" in text:
        reasons.append(
            "The message involves a password request."
        )

    if "kyc" in text:
        reasons.append(
            "The message uses KYC verification as a reason for requesting information."
        )

    if "verify" in text:
        reasons.append(
            "The message creates pressure to verify an account."
        )

    if "blocked" in text or "suspended" in text:
        reasons.append(
            "The message threatens account blocking or suspension."
        )

    if "urgent" in text or "immediately" in text:
        reasons.append(
            "The message uses urgency or pressure tactics."
        )

    if "send" in text and (
        "otp" in text
        or "pin" in text
        or "password" in text
    ):
        reasons.append(
            "The message asks the recipient to send sensitive credentials."
        )

    if "bank" in text or "sbi" in text:
        reasons.append(
            "The message impersonates or references a banking service."
        )

    return reasons