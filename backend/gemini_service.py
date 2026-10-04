import json
import os
import re
import time
from typing import Any

from dotenv import load_dotenv
from google import genai
from google.genai import types


# ============================================================
# ENVIRONMENT
# ============================================================

load_dotenv()

API_KEY = os.getenv("GEMINI_API_KEY")

if not API_KEY:
    raise RuntimeError(
        "GEMINI_API_KEY is not set. "
        "Check backend/.env"
    )


# ============================================================
# GEMINI CLIENT
# ============================================================

client = genai.Client(
    api_key=API_KEY
)


# ============================================================
# MODELS
# ============================================================
#
# Use a current model first.
#
# Google currently recommends newer models for new projects.
# We keep fallbacks so your app has a better chance of
# recovering if one model is temporarily unavailable.
#

MODELS = [
    "gemini-3.8-flash",
    "gemini-3.5-flash-lite",
    "gemini-3.6-flash",
]


# ============================================================
# SYSTEM INSTRUCTION
# ============================================================

SYSTEM_INSTRUCTION = """
You are Sangyan, an AI scam and phishing detection assistant.

Analyze the supplied content carefully.

Look for:

- OTP requests
- PIN requests
- password requests
- banking information requests
- UPI/payment requests
- suspicious links
- fake KYC requests
- account suspension threats
- prize/lottery scams
- fake customer support
- impersonation
- urgency and pressure
- job scams
- investment scams
- refund scams
- social engineering
- requests for confidential information
- malicious or suspicious instructions

IMPORTANT:

A message is suspicious if it attempts to trick the user,
pressure the user, impersonate an organization/person,
request sensitive information, request money, or direct
the user to a suspicious website.

Return ONLY valid JSON.

Use exactly this structure:

{
  "message": "original or extracted content",
  "analysis": "clear explanation",
  "is_scam": true,
  "scam_type": "type of scam",
  "risk_level": "High",
  "confidence": 0.95,
  "category": "Phishing"
}

Rules:

- is_scam must be true or false.
- risk_level must be exactly Low, Medium, or High.
- confidence must be a number between 0 and 1.
- category should be concise.
- Do not use markdown.
- Do not wrap JSON in ```json.
- Return ONLY JSON.
"""


# ============================================================
# GEMINI REQUEST
# ============================================================

def generate_with_fallback(contents: Any):
    """
    Try the configured Gemini models one by one.

    Handles temporary 503 errors and unavailable models.
    """

    last_error = None

    for model in MODELS:

        for attempt in range(2):

            try:

                print(
                    f"GEMINI REQUEST -> model={model}, "
                    f"attempt={attempt + 1}"
                )

                response = client.models.generate_content(
                    model=model,
                    contents=contents,
                )

                if not response:
                    raise RuntimeError(
                        "Gemini returned an empty response."
                    )

                text = getattr(
                    response,
                    "text",
                    None,
                )

                if not text:
                    raise RuntimeError(
                        "Gemini response did not contain text."
                    )

                print(
                    f"GEMINI SUCCESS -> model={model}"
                )

                return text

            except Exception as e:

                last_error = e

                error_text = str(e)

                print(
                    f"GEMINI ERROR -> model={model}: "
                    f"{error_text}"
                )

                # Retry temporary server errors.
                if (
                    "503" in error_text
                    or "UNAVAILABLE" in error_text
                    or "high demand" in error_text.lower()
                    or "temporarily" in error_text.lower()
                ):
                    if attempt == 0:
                        time.sleep(2)
                        continue

                # Try the next model.
                break

    raise RuntimeError(
        "Gemini analysis failed after trying all models. "
        f"Last error: {last_error}"
    )


# ============================================================
# TEXT ANALYSIS
# ============================================================

async def analyze_message(
    message: str,
) -> dict:

    prompt = f"""
{SYSTEM_INSTRUCTION}

Analyze this message:

{message}
"""

    response_text = generate_with_fallback(
        prompt
    )

    return parse_json_response(
        response_text,
        message,
    )


# ============================================================
# IMAGE ANALYSIS
# ============================================================

async def analyze_image(
    image_bytes: bytes,
    mime_type: str,
) -> dict:

    prompt = f"""
{SYSTEM_INSTRUCTION}

This is an uploaded screenshot or image.

First extract the useful text from the image.

Then analyze the extracted content for scam,
fraud, phishing, impersonation, or social engineering.

If there is no useful text, explain that clearly.

Return ONLY valid JSON.
"""

    image_part = types.Part.from_bytes(
        data=image_bytes,
        mime_type=mime_type,
    )

    contents = [
        prompt,
        image_part,
    ]

    response_text = generate_with_fallback(
        contents
    )

    return parse_json_response(
        response_text,
        "Text extracted from uploaded image.",
    )


# ============================================================
# JSON PARSER
# ============================================================

def parse_json_response(
    text: str,
    fallback_message: str,
) -> dict:

    if not text:
        return {
            "message": fallback_message,
            "analysis": "No response was received from Gemini.",
            "is_scam": False,
            "scam_type": "Unknown",
            "risk_level": "Unknown",
            "confidence": 0,
            "category": "Unknown",
        }

    cleaned = text.strip()

    # Remove markdown fences if Gemini accidentally returns them.
    cleaned = re.sub(
        r"^```json\s*",
        "",
        cleaned,
        flags=re.IGNORECASE,
    )

    cleaned = re.sub(
        r"^```\s*",
        "",
        cleaned,
    )

    cleaned = re.sub(
        r"\s*```$",
        "",
        cleaned,
    )

    # Sometimes Gemini puts extra text around JSON.
    start = cleaned.find("{")
    end = cleaned.rfind("}")

    if start != -1 and end != -1:
        cleaned = cleaned[start:end + 1]

    try:

        result = json.loads(cleaned)

        if not isinstance(result, dict):
            raise ValueError(
                "Gemini returned non-object JSON."
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
        }

    except Exception as e:

        print(
            "GEMINI JSON PARSE ERROR:",
            e,
        )

        print(
            "RAW GEMINI RESPONSE:",
            cleaned,
        )

        return {
            "message": fallback_message,
            "analysis": cleaned,
            "is_scam": False,
            "scam_type": "Unknown",
            "risk_level": "Unknown",
            "confidence": 0,
            "category": "Unknown",
        }


# ============================================================
# BOOLEAN PARSER
# ============================================================

def parse_bool(
    value: Any,
) -> bool:

    if isinstance(value, bool):
        return value

    if isinstance(value, str):

        return value.strip().lower() in {
            "true",
            "yes",
            "1",
        }

    if isinstance(value, (int, float)):

        return bool(value)

    return False


# ============================================================
# CONFIDENCE PARSER
# ============================================================

def parse_confidence(
    value: Any,
) -> float:

    try:

        confidence = float(value)

        # Gemini might return 95 instead of 0.95.
        if confidence > 1:
            confidence /= 100

        return max(
            0.0,
            min(
                confidence,
                1.0,
            ),
        )

    except Exception:

        return 0.0


# ============================================================
# RISK NORMALIZER
# ============================================================

def normalize_risk_level(
    value: Any,
) -> str:

    if not isinstance(value, str):
        return "Unknown"

    value = value.strip().lower()

    if value == "high":
        return "High"

    if value == "medium":
        return "Medium"

    if value == "low":
        return "Low"

    return "Unknown"