from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


def make_icon(out_path: Path) -> None:
    size = 256
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background gradient
    for y in range(size):
        t = y / (size - 1)
        r = int(120 + (255 - 120) * t)
        g = int(25 + (80 - 25) * t)
        b = int(170 + (235 - 170) * t)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    # Rounded card mask effect
    mask = Image.new("L", (size, size), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle((8, 8, size - 8, size - 8), radius=56, fill=255)
    img.putalpha(mask)

    # Inner glow overlay
    glow = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.rounded_rectangle((20, 20, size - 20, size - 20), radius=48, outline=(255, 255, 255, 70), width=4)
    glow = glow.filter(ImageFilter.GaussianBlur(1.2))
    img = Image.alpha_composite(img, glow)

    # Play triangle
    tri = [(102, 78), (102, 178), (184, 128)]
    draw = ImageDraw.Draw(img)
    draw.polygon(tri, fill=(255, 255, 255, 245))

    # Spark star
    cx, cy = 78, 74
    star = [
        (cx, cy - 14),
        (cx + 4, cy - 4),
        (cx + 14, cy),
        (cx + 4, cy + 4),
        (cx, cy + 14),
        (cx - 4, cy + 4),
        (cx - 14, cy),
        (cx - 4, cy - 4),
    ]
    draw.polygon(star, fill=(255, 255, 255, 230))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(
        out_path,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


if __name__ == "__main__":
    target = Path(__file__).resolve().parents[1] / "assets" / "nextdebut.ico"
    make_icon(target)
    print(f"Created: {target}")

