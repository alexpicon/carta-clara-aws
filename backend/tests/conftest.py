"""Shared pytest fixtures for the Carta Clara backend smoke tests.

These tests exercise the handlers end-to-end with mocked AWS clients — no AWS
account, no network. boto3 is never actually called: each handler's lazy
client cache (`helpers._CLIENTS`) is pre-seeded with fakes.

Loading note: all three handlers do `import helpers` and live as `handler.py`
in their own directory. `load_handler(name)` loads one handler in isolation by
putting its directory at the front of `sys.path` and clearing the cached
`handler` / `helpers` modules, so the three identical-named modules never
collide within a single pytest session.
"""

import base64
import importlib
import os
import sys
from pathlib import Path
from unittest.mock import MagicMock

import pytest

BACKEND = Path(__file__).resolve().parent.parent
SRC = BACKEND / "src"

# --- environment: set before any handler import -----------------------------
_TEST_ENV = {
    "BEDROCK_REGION": "us-west-2",
    "UPLOADS_BUCKET": "carta-clara-test-uploads",
    "REFUSAL_TABLE": "carta-clara-refusal-log-test",
    "MULTIMODAL_MODEL_ID": "us.anthropic.claude-sonnet-4-6",
    "TEXT_MODEL_ID": "us.anthropic.claude-sonnet-4-6",
    "FAST_MODEL_ID": "amazon.nova-pro-v1:0",
    "POLLY_VOICE": "Lupe",
    "GUARDRAIL_ID": "test-guardrail-id",
    "GUARDRAIL_VERSION": "DRAFT",
    "KNOWLEDGE_BASE_ID": "PLACEHOLDER",  # KB optional; retrieval degrades to []
}
for _k, _v in _TEST_ENV.items():
    os.environ.setdefault(_k, _v)

# A valid 100x100 PNG (checkerboard) — the KODA-05 placeholder test image.
TEST_PNG_B64 = (
    "iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAIAAAD/gAIDAAAAtUlEQVR42u3SMREAMBDDsCAJ"
    "f2TBUQq/dNNiAD6l7Ta9NC7cGxfIIossssgiywWyyCKLLLLIcoEsssgiiyyyXCCLLLLIIoss"
    "F8giiyyyyCLLBbLIIosssshygSyyyCKLLLJcIIssssgiiyyyXCCLLLLIIossF8j60gceyIXW"
    "7E1TMAAAAABJRU5ErkJggg=="
)
# Reduce the embedded image to a small valid PNG used across tests.
TEST_PNG_BYTES = base64.b64decode(TEST_PNG_B64)


# --- handler loader ---------------------------------------------------------


def _load_handler(name):
    """Load src/<name>/handler.py + its vendored helpers.py in isolation."""
    for mod in ("handler", "helpers"):
        sys.modules.pop(mod, None)
    handler_dir = str(SRC / name)
    while handler_dir in sys.path:
        sys.path.remove(handler_dir)
    sys.path.insert(0, handler_dir)
    helpers = importlib.import_module("helpers")
    handler = importlib.import_module("handler")
    helpers.reset_clients()
    return handler, helpers


@pytest.fixture
def load_handler():
    return _load_handler


# --- fake AWS clients -------------------------------------------------------


def converse_response(text, stop_reason="end_turn", blocked_topic=None):
    """Build a fake Bedrock Converse response."""
    trace = {}
    if blocked_topic:
        trace = {
            "guardrail": {
                "inputAssessment": {
                    "test-guardrail-id": {
                        "topicPolicy": {
                            "topics": [
                                {"name": blocked_topic, "type": "DENY",
                                 "action": "BLOCKED"}
                            ]
                        }
                    }
                }
            }
        }
    return {
        "output": {"message": {"content": [{"text": text}]}},
        "stopReason": stop_reason,
        "usage": {"inputTokens": 800, "outputTokens": 350},
        "trace": trace,
    }


def make_s3(found=True):
    """Fake S3 client. `found=False` makes get_object raise (expired document)."""
    s3 = MagicMock()
    s3.put_object.return_value = {}
    s3.generate_presigned_url.return_value = "https://s3.example/presigned?sig=test"
    if found:
        body = MagicMock()
        body.read.return_value = TEST_PNG_BYTES
        s3.get_object.return_value = {"Body": body}
    else:
        s3.get_object.side_effect = Exception("NoSuchKey")
    return s3


def make_polly():
    polly = MagicMock()
    stream = MagicMock()
    stream.read.return_value = b"\xff\xfb\x90fake-mp3-bytes"
    polly.synthesize_speech.return_value = {"AudioStream": stream}
    return polly


def make_dynamodb(items=None):
    """Fake DynamoDB resource. `.Table(name)` -> table with put_item / query."""
    table = MagicMock()
    table.put_item.return_value = {}
    table.query.return_value = {"Items": list(items or [])}
    resource = MagicMock()
    resource.Table.return_value = table
    resource._table = table  # test access shortcut
    return resource


@pytest.fixture
def fakes():
    """Bundle of fake-client builders for tests to seed helpers._CLIENTS."""
    return {
        "converse_response": converse_response,
        "make_s3": make_s3,
        "make_polly": make_polly,
        "make_dynamodb": make_dynamodb,
    }
