#!/usr/bin/env python3
"""Import unchanged Coolicons v4.1 SVGs matching the client screenshot labels.

git clone --depth 1 --branch v4.1 https://github.com/krystonschwarze/coolicons.git /tmp/coolicons-v4.1
python3 tool/import_supplemental_vectors.py /tmp/coolicons-v4.1
"""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
COMMIT = "42d70477683a0c44cd1732b32a9def8a94469c5a"
ALIASES = {
    "switch-left": "swicht-left",
    "switch-right": "swicht-right",
    "paperclip-attachment-horizontal": "paperclip-attechment-horizontal",
    "paperclip-attachment-tilt": "paperclip-attechment-tilt",
    "coffee-to-go": "coffe-to-go",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    args = parser.parse_args()
    commit = subprocess.check_output(
        ["git", "-C", str(args.checkout), "rev-parse", "HEAD"], text=True
    ).strip()
    if commit != COMMIT:
        parser.error(f"Expected Coolicons v4.1 commit {COMMIT}, got {commit}")
    originals = json.loads((ROOT / "tool/supplemental_icons.json").read_text())
    entries = []
    pending = []
    for original in originals:
        crop = Path(original["asset"])
        upstream = Path("coolicons.iconjar/icons") / (
            ALIASES.get(crop.stem, crop.stem) + ".svg"
        )
        data = (args.checkout / upstream).read_bytes()
        svg = ET.fromstring(data)
        if svg.tag != "{http://www.w3.org/2000/svg}svg" or any(
            node.tag.endswith("}image") for node in svg.iter()
        ):
            raise ValueError(f"Expected genuine vector artwork: {upstream}")
        asset = Path("assets/icons/vectors") / crop.parent.name / (crop.stem + ".svg")
        pending.append((ROOT / asset, data))
        entries.append({
            "asset": asset.as_posix(),
            "label": original["label"],
            "source": original["source"],
            "reference_crop": original["asset"],
            "upstream": upstream.as_posix(),
            "commit": COMMIT,
            "sha256": hashlib.sha256(data).hexdigest(),
        })
    # Validate the complete mapping before writing any assets.
    for destination, data in pending:
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
    (ROOT / "tool/supplemental_vectors.json").write_text(
        json.dumps(entries, indent=2) + "\n"
    )
    print(f"Imported {len(entries)} unchanged SVGs from Coolicons v4.1 ({COMMIT}).")


if __name__ == "__main__":
    main()
