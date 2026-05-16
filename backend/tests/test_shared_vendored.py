"""KODA-08 guard — the vendored helpers.py copies must match the canonical source.

If this fails, someone edited a handler-local helpers.py without re-vendoring.
Fix: edit backend/src/_shared/helpers.py, then run:
    for d in scan ask refusal_log; do cp src/_shared/helpers.py src/$d/helpers.py; done
"""

from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "src"


def test_vendored_helpers_match_canonical():
    canonical = (SRC / "_shared" / "helpers.py").read_text(encoding="utf-8")
    for name in ("scan", "ask", "refusal_log", "scan_packet"):
        vendored = (SRC / name / "helpers.py").read_text(encoding="utf-8")
        assert vendored == canonical, f"src/{name}/helpers.py has drifted from _shared"
