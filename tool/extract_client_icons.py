#!/usr/bin/env python3
"""Extract exact RGBA crops from the original client sheets (requires Pillow)."""

import argparse
import json
from pathlib import Path

from PIL import Image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--check', action='store_true', help='Verify existing crops without writing.'
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    entries = json.loads((root / 'tool/client_icons.json').read_text())
    sources = {}
    paths = set()
    for entry in entries:
        asset = root / entry['asset']
        if asset in paths:
            raise ValueError(f'Duplicate asset: {asset}')
        paths.add(asset)
        source_path = entry['source']
        if source_path not in sources:
            sources[source_path] = Image.open(root / source_path).convert('RGBA')
        source = sources[source_path]
        x, y, width, height = entry['rect']
        crop = source.crop((x, y, x + width, y + height))
        if not crop.getchannel('A').getbbox():
            raise ValueError(f'Empty icon: {asset}')
        if args.check:
            with Image.open(asset) as existing:
                if existing.mode != crop.mode or existing.size != crop.size:
                    raise ValueError(f'Icon format differs from source: {asset}')
                if existing.tobytes() != crop.tobytes():
                    raise ValueError(f'Icon pixels differ from source: {asset}')
        else:
            asset.parent.mkdir(parents=True, exist_ok=True)
            crop.save(asset)
    action = 'Verified' if args.check else 'Extracted'
    print(f'{action} {len(entries)} icons from {len(sources)} original sheets.')


if __name__ == '__main__':
    main()
