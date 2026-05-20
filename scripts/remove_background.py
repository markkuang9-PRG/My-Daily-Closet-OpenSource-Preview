from __future__ import annotations

import sys
from io import BytesIO
from pathlib import Path

from PIL import Image
from rembg import remove


def build_centered_png(image_bytes: bytes) -> bytes:
    image = Image.open(BytesIO(image_bytes)).convert("RGBA")
    bbox = image.getbbox()
    if bbox:
        image = image.crop(bbox)

    width, height = image.size
    largest = max(width, height, 1)
    padding = max(int(largest * 0.18), 48)
    canvas_size = largest + padding * 2

    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    x = (canvas_size - width) // 2
    y = (canvas_size - height) // 2
    canvas.alpha_composite(image, (x, y))

    output = BytesIO()
    canvas.save(output, format="PNG")
    return output.getvalue()


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: remove_background.py <input> <output>", file=sys.stderr)
        return 2

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])

    source = input_path.read_bytes()
    removed = remove(source)
    processed = build_centered_png(removed)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(processed)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
