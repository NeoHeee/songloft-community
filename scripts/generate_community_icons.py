from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZE = 1024
assets = Path("assets/icons")
assets.mkdir(parents=True, exist_ok=True)

base = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
pixels = base.load()
start = (190, 85, 255)
end = (48, 24, 164)
for y in range(SIZE):
    for x in range(SIZE):
        t = (x + y) / (2 * (SIZE - 1))
        pixels[x, y] = tuple(
            round(start[i] * (1 - t) + end[i] * t) for i in range(3)
        ) + (255,)

rounded_mask = Image.new("L", (SIZE, SIZE), 0)
ImageDraw.Draw(rounded_mask).rounded_rectangle(
    (12, 12, SIZE - 12, SIZE - 12),
    radius=205,
    fill=255,
)
base.putalpha(rounded_mask)

glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow)
glow_draw.ellipse((-180, -160, 690, 660), fill=(255, 148, 255, 90))
glow_draw.ellipse((360, 220, 1180, 1080), fill=(111, 63, 255, 85))
base = Image.alpha_composite(
    base,
    glow.filter(ImageFilter.GaussianBlur(110)),
)

font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
font = ImageFont.truetype(font_path, 690)
glyph_mask = Image.new("L", (SIZE, SIZE), 0)
glyph_draw = ImageDraw.Draw(glyph_mask)
bbox = glyph_draw.textbbox((0, 0), "S", font=font)
glyph_draw.text(
    (
        (SIZE - (bbox[2] - bbox[0])) / 2 - bbox[0],
        (SIZE - (bbox[3] - bbox[1])) / 2 - bbox[1] - 10,
    ),
    "S",
    font=font,
    fill=255,
)

bars = Image.new("L", (SIZE, SIZE), 0)
bars_draw = ImageDraw.Draw(bars)
bar_width = 23
for x in range(230, 795, 41):
    active = [
        y
        for y in range(150, 875)
        if glyph_mask.getpixel((x + bar_width // 2, y)) > 32
    ]
    if not active:
        continue
    runs = []
    start_y = previous = active[0]
    for y in active[1:]:
        if y - previous > 3:
            runs.append((start_y, previous))
            start_y = y
        previous = y
    runs.append((start_y, previous))
    for top, bottom in runs:
        if bottom - top >= 14:
            bars_draw.rounded_rectangle(
                (x, top, x + bar_width, bottom),
                radius=bar_width // 2,
                fill=255,
            )

soft_glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
soft_glow.paste((255, 255, 255, 165), mask=bars)
base = Image.alpha_composite(
    base,
    soft_glow.filter(ImageFilter.GaussianBlur(24)),
)

waveform = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
waveform.paste((255, 255, 255, 245), mask=bars)
base = Image.alpha_composite(base, waveform)
base.save(assets / "app_icon.png", optimize=True)

foreground = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
compact = waveform.resize((720, 720), Image.Resampling.LANCZOS)
foreground.alpha_composite(
    compact,
    ((SIZE - 720) // 2, (SIZE - 720) // 2),
)
foreground.save(assets / "app_icon_foreground.png", optimize=True)

mono = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
mono_mask = bars.resize((720, 720), Image.Resampling.LANCZOS)
mono.paste(
    (255, 255, 255, 255),
    ((SIZE - 720) // 2, (SIZE - 720) // 2),
    mono_mask,
)
mono.save(assets / "app_icon_monochrome.png", optimize=True)

launch = Image.new("RGBA", (1200, 700), (0, 0, 0, 0))
launch.alpha_composite(
    base.resize((250, 250), Image.Resampling.LANCZOS),
    ((1200 - 250) // 2, 40),
)
draw = ImageDraw.Draw(launch)
latin = ImageFont.truetype(font_path, 62)
latin_small = ImageFont.truetype(font_path, 30)
cjk = ImageFont.truetype("fonts/NotoSansSC-Regular.otf", 38)


def centered(text, y, font, fill):
    box = draw.textbbox((0, 0), text, font=font)
    draw.text(
        ((1200 - (box[2] - box[0])) / 2, y),
        text,
        font=font,
        fill=fill,
    )


centered(
    "Songloft Community",
    325,
    latin,
    (255, 255, 255, 255),
)
centered(
    "社区增强版音乐播放器",
    415,
    cjk,
    (218, 198, 255, 255),
)
centered(
    "Community Edition · 1.0.0-community.1",
    492,
    latin_small,
    (184, 154, 255, 255),
)
launch_dir = Path("android/app/src/main/res/drawable-nodpi")
launch_dir.mkdir(parents=True, exist_ok=True)
launch.save(launch_dir / "launch_brand.png", optimize=True)

web_icons = Path("web/icons")
web_icons.mkdir(parents=True, exist_ok=True)
for icon_size in (192, 512):
    resized = base.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    resized.save(web_icons / f"Icon-{icon_size}.png", optimize=True)
    resized.save(web_icons / f"Icon-maskable-{icon_size}.png", optimize=True)

windows_icon = Path("windows/runner/resources/app_icon.ico")
windows_icon.parent.mkdir(parents=True, exist_ok=True)
base.save(
    windows_icon,
    format="ICO",
    sizes=[
        (16, 16),
        (24, 24),
        (32, 32),
        (48, 48),
        (64, 64),
        (128, 128),
        (256, 256),
    ],
)
