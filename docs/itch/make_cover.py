# Regenerates the itch.io cover from docs/screenshot.png (needs Pillow, macOS Avenir Next).
from PIL import Image, ImageDraw, ImageFont

import os
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AVENIR = "/System/Library/Fonts/Avenir Next.ttc"
W, H = 1260, 1000                      # 2x itch.io's 630x500 cover
YELLOW, INK, BEZEL = (255, 196, 32), (30, 28, 24), (42, 40, 36)

shot = Image.open(f"{ROOT}/docs/screenshot.png").convert("RGB")
big = shot.resize((shot.width * 2, shot.height * 2), Image.NEAREST)   # crisp pixels


im = Image.new("RGB", (W, H), YELLOW)
d = ImageDraw.Draw(im)

title = ImageFont.truetype(AVENIR, 150, index=8)      # Heavy
tag = ImageFont.truetype(AVENIR, 46, index=2)         # Demi Bold
d.text((W / 2, 60), "Pomodial", font=title, fill=INK, anchor="mt")
d.multiline_text((W / 2, 250), "A visual timer for your Playdate,\nwound with the crank.",
                 font=tag, fill=INK, anchor="ma", align="center", spacing=10)

# Screen in a dark bezel, like the device
pad = 26
sx, sy = (W - big.width) // 2, 420
d.rounded_rectangle((sx - pad, sy - pad, sx + big.width + pad, sy + big.height + pad),
                    radius=30, fill=BEZEL)
im.paste(big, (sx, sy))

im.save(f"{ROOT}/docs/itch/cover.png")
im.resize((630, 500), Image.LANCZOS).save(f"{ROOT}/docs/itch/cover-630x500.png")
print("ok")
