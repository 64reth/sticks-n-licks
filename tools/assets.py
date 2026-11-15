"""Optional offline PNG validation, lossless slicing, and SpriteFrames export."""
import argparse
import hashlib
import json
import re
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def validate(source, cell=(96, 96), expected=1, max_colors=64, max_size_drift=12):
    source = Path(source)
    errors = []
    with Image.open(source) as original:
        if original.format != "PNG" or original.mode != "RGBA":
            errors.append("Source must be a genuine RGBA PNG")
        image = original.convert("RGBA")
    w, h = image.size
    cw, ch = cell
    if min(cw, ch, expected) <= 0:
        raise ValueError("Positive cell dimensions and frame count required")
    if w % cw or h % ch:
        errors.append("Sheet dimensions are not exact multiples of frame cells")
    count = (w // cw) * (h // ch)
    if count != expected:
        errors.append(f"Expected {expected} frames, found {count}")
    alpha = image.getchannel("A")
    if alpha.getextrema() != (0, 255):
        errors.append("Requires both fully transparent and opaque pixels")
    colors = set()
    boxes = []
    for y in range(0, h - ch + 1, ch):
        for x in range(0, w - cw + 1, cw):
            frame = image.crop((x, y, x + cw, y + ch))
            a = frame.getchannel("A")
            box = a.getbbox()
            boxes.append(box)
            if box is None:
                errors.append(f"Empty frame {len(boxes)-1}")
                continue
            if box[0] == 0 or box[1] == 0 or box[2] == cw or box[3] == ch:
                errors.append(f"Frame {len(boxes)-1} touches a cell boundary")
            for r, g, b, opacity in frame.getdata():
                if opacity not in (0, 255):
                    errors.append(f"Frame {len(boxes)-1} has non-pixel-art partial alpha")
                    break
                if opacity:
                    colors.add((r, g, b))
    if len(colors) > max_colors:
        errors.append(f"Palette has {len(colors)} colors; limit {max_colors}")
    sizes = [(b[2]-b[0], b[3]-b[1]) for b in boxes if b]
    if sizes and any(max(v[i] for v in sizes)-min(v[i] for v in sizes) > max_size_drift for i in (0, 1)):
        errors.append("Frame silhouette size drift exceeds limit; review consistency")
    return {"status": "passed" if not errors else "failed", "errors": errors,
            "dimensions": [w, h], "cell": list(cell), "frames": count,
            "palette_colors": len(colors), "frame_bounds": boxes,
            "identity_review": "required", "sha256": digest(source)}

def export(source, destination, animation, expected, reference=None, cell=(96, 96), visual_approved=False):
    if not re.fullmatch(r"[a-z][a-z0-9_]*", animation):
        raise ValueError("Animation must be a lowercase identifier")
    source, destination = Path(source).resolve(), Path(destination).resolve()
    destination.relative_to(ROOT)
    validation = validate(source, cell, expected)
    if validation["status"] != "passed":
        raise ValueError(json.dumps(validation))
    # A fresh directory is mandatory. Never replace source or approved exports.
    destination.mkdir(parents=True, exist_ok=False)
    generated = []
    with Image.open(source) as sheet:
        for i in range(expected):
            x = i % (sheet.width // cell[0]) * cell[0]
            y = i // (sheet.width // cell[0]) * cell[1]
            target = destination / f"{animation}_{i:03d}.png"
            sheet.crop((x, y, x+cell[0], y+cell[1])).save(target, format="PNG")
            generated.append(target)
    refs = []
    for i, target in enumerate(generated):
        relative = target.relative_to(ROOT).as_posix()
        refs.append(f'[ext_resource type="Texture2D" path="res://{relative}" id="{i+1}"]')
    frames = ', '.join('{"duration": 1.0, "texture": ExtResource("%d")}' % (i+1) for i in range(expected))
    resource = f'[gd_resource type="SpriteFrames" load_steps={expected+1} format=3]\n' + '\n'.join(refs) + f'\n[resource]\nanimations = [{{"frames": [{frames}], "loop": true, "name": &"{animation}", "speed": 8.0}}]\n'
    (destination / f"{animation}.tres").write_text(resource)
    manifest = {"animation": animation, "expected_frames": expected,
                "source": str(source.relative_to(ROOT)), "source_sha256": digest(source),
                "source_reference": reference, "generated_files": [str(p.relative_to(ROOT)) for p in generated],
                "validation": validation, "visual_approved": visual_approved,
                "godot_resource": str((destination / f"{animation}.tres").relative_to(ROOT))}
    (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("source", type=Path)
    p.add_argument("--frames", type=int, required=True)
    p.add_argument("--cell", type=int, nargs=2, default=(96,96))
    p.add_argument("--export", type=Path)
    p.add_argument("--animation", default="idle")
    p.add_argument("--reference")
    args = p.parse_args()
    result = export(args.source, args.export, args.animation, args.frames, args.reference, tuple(args.cell)) if args.export else validate(args.source, tuple(args.cell), args.frames)
    print(json.dumps(result, indent=2))
    return 1 if result.get("status") == "failed" else 0

if __name__ == "__main__":
    raise SystemExit(main())
