from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024
CENTER = SIZE // 2

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# --- Background: rounded square with purple gradient ---
# Create gradient manually
for y in range(SIZE):
    ratio = y / SIZE
    r = int(88 + (108 - 88) * ratio)    # 6C5CE7 -> #6C3CE0
    g = int(92 + (60 - 92) * ratio)
    b = int(231 + (224 - 231) * ratio)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))

# Mask to rounded rectangle
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
radius = int(SIZE * 0.22)
mask_draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=radius, fill=255)
img.putalpha(mask)

# --- Draw stacked photo cards ---

def draw_rounded_rect(draw_obj, bbox, radius, fill, outline=None, width=0):
    draw_obj.rounded_rectangle(bbox, radius=radius, fill=fill, outline=outline, width=width)

def draw_card(draw_obj, cx, cy, w, h, angle_deg, fill, shadow_color=None, border_color=None):
    """Draw a rotated rounded rectangle card"""
    card_img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    card_draw = ImageDraw.Draw(card_img)

    left = cx - w // 2
    top = cy - h // 2

    # Shadow
    if shadow_color:
        card_draw.rounded_rectangle(
            [left + 6, top + 6, left + w + 6, top + h + 6],
            radius=24, fill=shadow_color
        )

    # Card body
    card_draw.rounded_rectangle(
        [left, top, left + w, top + h],
        radius=24, fill=fill
    )

    # Border
    if border_color:
        card_draw.rounded_rectangle(
            [left, top, left + w, top + h],
            radius=24, outline=border_color, width=4
        )

    # Fake photo area (darker rectangle inside)
    margin = 20
    photo_top = top + margin
    photo_bottom = top + h - 70
    card_draw.rounded_rectangle(
        [left + margin, photo_top, left + w - margin, photo_bottom],
        radius=12, fill=(200, 200, 210, 80)
    )

    # Little landscape icon in photo area
    photo_cx = left + w // 2
    photo_cy = (photo_top + photo_bottom) // 2
    # Mountain shape
    points_mountain = [
        (photo_cx - 60, photo_cy + 30),
        (photo_cx - 20, photo_cy - 25),
        (photo_cx + 10, photo_cy + 5),
        (photo_cx + 30, photo_cy - 35),
        (photo_cx + 70, photo_cy + 30),
    ]
    card_draw.polygon(points_mountain, fill=(255, 255, 255, 100))
    # Sun
    card_draw.ellipse(
        [photo_cx + 30, photo_cy - 55, photo_cx + 60, photo_cy - 25],
        fill=(255, 255, 255, 100)
    )

    # Rotate
    if angle_deg != 0:
        card_img = card_img.rotate(angle_deg, center=(cx, cy), expand=False, resample=Image.BICUBIC)

    return card_img

# Back card (slightly rotated left, dimmer)
back_card = draw_card(draw, CENTER, CENTER + 20, 380, 480, 8,
                       fill=(255, 255, 255, 90),
                       shadow_color=(0, 0, 0, 30))
img = Image.alpha_composite(img, back_card)

# Middle card (slightly rotated right)
mid_card = draw_card(draw, CENTER - 10, CENTER + 10, 380, 480, -4,
                      fill=(255, 255, 255, 160),
                      shadow_color=(0, 0, 0, 40))
img = Image.alpha_composite(img, mid_card)

# Front card (being swiped right - offset and rotated)
front_card = draw_card(draw, CENTER + 60, CENTER - 10, 380, 480, -12,
                        fill=(255, 255, 255, 240),
                        shadow_color=(0, 0, 0, 50))
img = Image.alpha_composite(img, front_card)

# --- Draw swipe arrow / check mark on front card ---
overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
overlay_draw = ImageDraw.Draw(overlay)

# Green circle (keep/success indicator) on front card area
circle_cx = CENTER + 140
circle_cy = CENTER - 80
circle_r = 52
overlay_draw.ellipse(
    [circle_cx - circle_r, circle_cy - circle_r,
     circle_cx + circle_r, circle_cy + circle_r],
    fill=(38, 222, 129, 220)  # success green
)

# Checkmark in the circle
check_points = [
    (circle_cx - 22, circle_cy + 2),
    (circle_cx - 6, circle_cy + 20),
    (circle_cx + 24, circle_cy - 16),
]
overlay_draw.line(check_points, fill=(255, 255, 255, 255), width=9, joint='curve')

# Red circle (delete indicator) on opposite side
red_cx = CENTER - 100
red_cy = CENTER + 140
red_r = 40
overlay_draw.ellipse(
    [red_cx - red_r, red_cy - red_r,
     red_cx + red_r, red_cy + red_r],
    fill=(255, 107, 107, 180)  # danger red
)

# X mark in red circle
x_size = 14
overlay_draw.line(
    [(red_cx - x_size, red_cy - x_size), (red_cx + x_size, red_cy + x_size)],
    fill=(255, 255, 255, 255), width=7
)
overlay_draw.line(
    [(red_cx + x_size, red_cy - x_size), (red_cx - x_size, red_cy + x_size)],
    fill=(255, 255, 255, 255), width=7
)

# Swipe trail (subtle curved line showing swipe direction)
trail_points = []
for t in range(20):
    x = CENTER - 40 + t * 12
    y = CENTER + 50 - int(30 * math.sin(t * 0.2))
    trail_points.append((x, y))

for i in range(len(trail_points) - 1):
    alpha = int(40 + (180 - 40) * (i / len(trail_points)))
    overlay_draw.line(
        [trail_points[i], trail_points[i + 1]],
        fill=(255, 255, 255, alpha), width=5
    )

img = Image.alpha_composite(img, overlay)

# --- Save as 1024x1024 ---
final = img.convert('RGB')  # iOS icons need RGB, no alpha on final
# Re-apply rounded corners on RGB
bg = Image.new('RGB', (SIZE, SIZE), (108, 92, 231))  # fallback bg color
bg.paste(final, (0, 0))

final.save('D:/SwipeClean/app_icon_1024.png', 'PNG')
print(f'Icon saved: {SIZE}x{SIZE}')

# Generate all required iOS sizes
ios_sizes = [
    (20, 1), (20, 2), (20, 3),
    (29, 1), (29, 2), (29, 3),
    (40, 1), (40, 2), (40, 3),
    (60, 2), (60, 3),
    (76, 1), (76, 2),
    (83.5, 2),
    (1024, 1),
]

import os
icon_dir = 'D:/SwipeClean/ios/Runner/Assets.xcassets/AppIcon.appiconset'
os.makedirs(icon_dir, exist_ok=True)

for base_size, scale in ios_sizes:
    pixel_size = int(base_size * scale)
    resized = final.resize((pixel_size, pixel_size), Image.LANCZOS)
    filename = f'Icon-App-{base_size}x{base_size}@{scale}x.png'
    resized.save(os.path.join(icon_dir, filename), 'PNG')
    print(f'  Generated {filename} ({pixel_size}x{pixel_size})')

print('All icons generated!')
