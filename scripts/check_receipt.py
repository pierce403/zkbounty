#!/usr/bin/env python3
"""Integration checks for an existing real receipt; run after README's prove command."""
import json
import pathlib
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parents[1]
receipt = root / "artifacts/receipt.json"
host = root / "target/debug/zkbounty-host"
bounty = "01" * 32
claimant = "02" * 32


def check(path, b, c, succeeds):
    result = subprocess.run(
        [str(host), "verify", str(path), b, c], capture_output=True, text=True
    )
    assert (result.returncode == 0) == succeeds, result.stderr


check(receipt, bounty, claimant, True)
check(receipt, "03" * 32, claimant, False)
check(receipt, bounty, "03" * 32, False)
data = json.loads(receipt.read_text())
data["journal"]["bytes"][0] ^= 1
with tempfile.TemporaryDirectory() as tmp:
    altered = pathlib.Path(tmp) / "altered.json"
    altered.write_text(json.dumps(data))
    check(altered, bounty, claimant, False)
print("Real receipt verified; wrong bounty, wrong claimant, and tampered journal rejected.")
