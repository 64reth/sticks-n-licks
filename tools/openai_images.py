"""Optional single-image OpenAI adapter. Defaults to a free, offline request plan."""
import argparse
import base64
import fcntl
import hashlib
import json
import os
import uuid
from datetime import datetime, timezone
from pathlib import Path
from assets import ROOT, digest

OUTPUT_PRICES = {"low": 0.009, "medium": 0.034, "high": 0.133}

def plan(prompt, config, reference=None, animation="concept", expected_frames=1):
    if config["model"] != "gpt-image-1.5" or config["size"] != "1024x1024":
        raise ValueError("Only the documented gpt-image-1.5 1024x1024 pricing profile is enabled")
    if not prompt.strip() or len(prompt) > config["max_prompt_chars"]:
        raise ValueError("Empty prompt or prompt limit exceeded")
    if expected_frames < 1 or not animation.replace("_", "").isalnum():
        raise ValueError("Valid animation name and positive expected frames required")
    ref = None
    if reference:
        reference = Path(reference).resolve()
        relative = reference.relative_to(ROOT).as_posix()
        sha = digest(reference)
        if config["approved_references"].get(relative) != sha:
            raise ValueError("Reference must be explicitly approved by path and SHA256 in config")
        if reference.stat().st_size > config["max_reference_bytes"]:
            raise ValueError("Reference exceeds byte limit")
        ref = {"path": relative, "sha256": sha}
    price = OUTPUT_PRICES[config["quality"]]
    reservation = config["reserve_per_request_usd"]
    if reservation < price or reservation > config["budget_usd"] or config["max_requests"] < 1:
        raise ValueError("Invalid generation limits")
    request = {"model": config["model"], "size": config["size"], "quality": config["quality"],
               "background": "transparent", "output_format": "png", "n": 1, "prompt": prompt}
    result = {"animation": animation, "expected_frames": expected_frames, "request": request, "reference": ref, "output_estimate_usd": price,
              "reserved_usd": reservation, "input_cost": "additional; invoice is authoritative"}
    result["approval_id"] = hashlib.sha256(json.dumps(result, sort_keys=True).encode()).hexdigest()
    return result

def execute(proposal, config, approval_id):
    if approval_id != proposal["approval_id"]:
        raise ValueError("Explicit single-request approval must match the dry-run approval ID")
    if not os.environ.get("OPENAI_API_KEY"):
        raise ValueError("Set OPENAI_API_KEY in your local environment; never paste or commit it")
    from openai import OpenAI
    output = ROOT / "assets/generated"
    output.mkdir(parents=True, exist_ok=True)
    # Lock and reserve before dispatch. Keep uncertain failed requests charged against limits.
    with (output / ".generation.lock").open("a+") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        ledger_path = output / "cost_ledger.json"
        ledger = json.loads(ledger_path.read_text()) if ledger_path.exists() else []
        if any(row["approval_id"] == approval_id for row in ledger):
            raise ValueError("This single-request approval has already been consumed")
        if len(ledger) >= config["max_requests"] or sum(r["reserved_usd"] for r in ledger) + proposal["reserved_usd"] > config["budget_usd"] + 1e-9:
            raise ValueError("Generation count or reserved budget limit reached")
        target = output / (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "_" + uuid.uuid4().hex)
        target.mkdir(exist_ok=False)
        record = {"id": target.name, "reserved_usd": proposal["reserved_usd"], "status": "reserved", "approval_id": approval_id}
        ledger.append(record)
        ledger_path.write_text(json.dumps(ledger, indent=2) + "\n")
        (target / "request.json").write_text(json.dumps(proposal, indent=2) + "\n")
        manifest = {"animation": proposal["animation"], "expected_frames": proposal["expected_frames"],
                    "source_reference": proposal["reference"], "generated_files": [],
                    "validation": {"status": "not_run"}, "approval_id": approval_id}
        (target / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
        try:
            client = OpenAI(max_retries=0, timeout=180.0)
            ref = proposal["reference"]
            if ref:
                ref_path = ROOT / ref["path"]
                if digest(ref_path) != ref["sha256"]:
                    raise ValueError("Approved reference changed")
                with ref_path.open("rb") as image:
                    result = client.images.edit(image=image, input_fidelity="high", **proposal["request"])
            else:
                result = client.images.generate(**proposal["request"])
            raw = base64.b64decode(result.data[0].b64_json, validate=True)
            with (target / "original.png").open("xb") as stream:
                stream.write(raw)
            metadata = result.model_dump(exclude={"data"})
            (target / "response.json").write_text(json.dumps(metadata, indent=2) + "\n")
            record["status"] = "received_unvalidated"
            record["usage"] = metadata.get("usage")
            usage = metadata.get("usage") or {}
            details = usage.get("input_tokens_details") or {}
            if "output_tokens" in usage and details:
                record["estimated_cost_usd"] = (details.get("text_tokens", 0) * 5 + details.get("image_tokens", 0) * 8 + usage["output_tokens"] * 32) / 1_000_000
            else:
                record["estimated_cost_usd"] = None
            manifest["generated_files"] = [str((target / "original.png").relative_to(ROOT))]
            manifest["source_sha256"] = digest(target / "original.png")
            (target / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
            # Raw generated files are never resized, quantised or overwritten.
            print(str(target / "original.png"))
        except Exception:
            record["status"] = "failed_or_unknown_charge"
            raise RuntimeError("Image request failed; reservation retained. Review provider usage before retrying.") from None
        finally:
            ledger_path.write_text(json.dumps(ledger, indent=2) + "\n")

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--prompt-file", type=Path, required=True)
    p.add_argument("--reference", type=Path)
    p.add_argument("--animation", default="concept")
    p.add_argument("--expected-frames", type=int, default=1)
    p.add_argument("--config", type=Path, default=ROOT / "tools/image_config.json")
    p.add_argument("--approve-single", help="Only supply after explicit user approval of this request ID")
    args = p.parse_args()
    config = json.loads(args.config.read_text())
    proposal = plan(args.prompt_file.read_text(), config, args.reference, args.animation, args.expected_frames)
    if args.approve_single:
        execute(proposal, config, args.approve_single)
    else:
        print(json.dumps(proposal, indent=2))

if __name__ == "__main__":
    main()
