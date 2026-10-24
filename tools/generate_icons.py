import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_gitora_icon_svg(filepath):
    svg_content = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="100%" height="100%">
  <defs>
    <!-- Background Gradient -->
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#1E1E2E" />
      <stop offset="50%" stop-color="#181825" />
      <stop offset="100%" stop-color="#11111B" />
    </linearGradient>

    <!-- Border Glow -->
    <linearGradient id="borderGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#6366F1" stop-opacity="0.8" />
      <stop offset="50%" stop-color="#A855F7" stop-opacity="0.5" />
      <stop offset="100%" stop-color="#3B82F6" stop-opacity="0.2" />
    </linearGradient>

    <!-- Main Branch Gradient -->
    <linearGradient id="mainBranchGrad" x1="0%" y1="100%" x2="0%" y2="0%">
      <stop offset="0%" stop-color="#3B82F6" />
      <stop offset="50%" stop-color="#6366F1" />
      <stop offset="100%" stop-color="#818CF8" />
    </linearGradient>

    <!-- Feature Branch Gradient -->
    <linearGradient id="featureBranchGrad" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#6366F1" />
      <stop offset="60%" stop-color="#A855F7" />
      <stop offset="100%" stop-color="#EC4899" />
    </linearGradient>

    <!-- Node Glow Filters -->
    <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="8" result="blur" />
      <feComposite in="SourceGraphic" in2="blur" operator="over" />
    </filter>
  </defs>

  <!-- Squircle Base -->
  <rect x="24" y="24" width="464" height="464" rx="104" ry="104" fill="url(#bgGrad)" stroke="url(#borderGrad)" stroke-width="6" />

  <!-- Background Decorative Grid Lines -->
  <path d="M120 40 L120 472 M256 40 L256 472 M392 40 L392 472" stroke="#313244" stroke-width="1.5" stroke-dasharray="6,6" opacity="0.3" />

  <!-- Main Trunk (Vertical Line) -->
  <line x1="176" y1="390" x2="176" y2="120" stroke="url(#mainBranchGrad)" stroke-width="28" stroke-linecap="round" />

  <!-- Feature Branch (Curving to the right) -->
  <path d="M176 280 C176 190, 336 270, 336 170" fill="none" stroke="url(#featureBranchGrad)" stroke-width="24" stroke-linecap="round" />

  <!-- Re-merge / Connecting Accent (Subtle flow) -->
  <path d="M336 170 C336 120, 230 130, 186 122" fill="none" stroke="#EC4899" stroke-width="8" stroke-linecap="round" stroke-dasharray="8,8" opacity="0.7" />

  <!-- Node 1: Root Commit -->
  <g filter="url(#glow)">
    <circle cx="176" cy="380" r="32" fill="#181825" stroke="#3B82F6" stroke-width="12" />
    <circle cx="176" cy="380" r="14" fill="#60A5FA" />
  </g>

  <!-- Node 2: Fork Commit -->
  <g filter="url(#glow)">
    <circle cx="176" cy="280" r="32" fill="#181825" stroke="#6366F1" stroke-width="12" />
    <circle cx="176" cy="280" r="14" fill="#818CF8" />
  </g>

  <!-- Node 3: Trunk HEAD Commit -->
  <g filter="url(#glow)">
    <circle cx="176" cy="130" r="34" fill="#181825" stroke="#818CF8" stroke-width="14" />
    <circle cx="176" cy="130" r="16" fill="#FFFFFF" />
  </g>

  <!-- Node 4: Feature Branch Commit -->
  <g filter="url(#glow)">
    <circle cx="336" cy="170" r="32" fill="#181825" stroke="#EC4899" stroke-width="12" />
    <circle cx="336" cy="170" r="14" fill="#F472B6" />
  </g>
</svg>'''
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(svg_content)
    print(f"Created SVG: {filepath}")

def render_raster_icon(size=512):
    # Render crisp raster bitmap using Pillow
    scale = 2
    actual_size = size * scale
    im = Image.new("RGBA", (actual_size, actual_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    pad = int(24 * actual_size / 512)
    radius = int(104 * actual_size / 512)

    # Squircle background
    box = (pad, pad, actual_size - pad, actual_size - pad)
    
    # Fill rounded rect
    draw.rounded_rectangle(box, radius=radius, fill=(24, 24, 37, 255), outline=(99, 102, 241, 200), width=int(6 * actual_size / 512))

    # Inner gradient / subtle highlight
    inner_pad = pad + int(12 * actual_size / 512)
    inner_box = (inner_pad, inner_pad, actual_size - inner_pad, actual_size - inner_pad)
    draw.rounded_rectangle(inner_box, radius=radius - int(8 * actual_size / 512), outline=(168, 85, 247, 50), width=int(2 * actual_size / 512))

    # Geometry calculations based on 512 canvas
    def c(val): return int(val * actual_size / 512)

    # Main trunk
    draw.line([(c(176), c(380)), (c(176), c(130))], fill=(99, 102, 241, 255), width=c(28))

    # Feature branch curve: sample cubic bezier
    p0 = (c(176), c(280))
    p1 = (c(176), c(190))
    p2 = (c(336), c(270))
    p3 = (c(336), c(170))
    
    points = []
    for step in range(101):
        t = step / 100.0
        # B(t) = (1-t)^3 p0 + 3(1-t)^2 t p1 + 3(1-t) t^2 p2 + t^3 p3
        x = (1-t)**3 * p0[0] + 3*(1-t)**2 * t * p1[0] + 3*(1-t) * t**2 * p2[0] + t**3 * p3[0]
        y = (1-t)**3 * p0[1] + 3*(1-t)**2 * t * p1[1] + 3*(1-t) * t**2 * p2[1] + t**3 * p3[1]
        points.append((x, y))

    draw.line(points, fill=(236, 72, 153, 255), width=c(24))

    # Draw nodes
    def draw_node(cx, cy, r_outer, r_inner, border_color, inner_color):
        # Outer glow ring
        draw.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer], fill=(24, 24, 37, 255), outline=border_color, width=c(12))
        # Inner dot
        draw.ellipse([cx - r_inner, cy - r_inner, cx + r_inner, cy + r_inner], fill=inner_color)

    # Node 1: Root commit
    draw_node(c(176), c(380), c(32), c(14), (59, 130, 246, 255), (96, 165, 250, 255))
    # Node 2: Fork commit
    draw_node(c(176), c(280), c(32), c(14), (99, 102, 241, 255), (129, 140, 248, 255))
    # Node 3: Trunk HEAD commit
    draw_node(c(176), c(130), c(34), c(16), (129, 140, 248, 255), (255, 255, 255, 255))
    # Node 4: Feature branch commit
    draw_node(c(336), c(170), c(32), c(14), (236, 72, 153, 255), (244, 114, 182, 255))

    # Downsample with Lanczos for anti-aliasing
    final_im = im.resize((size, size), Image.Resampling.LANCZOS)
    return final_im

def main():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    branding_dir = os.path.join(base_dir, "assets", "branding")
    os.makedirs(branding_dir, exist_ok=True)

    # 1. Generate SVG
    svg_path = os.path.join(branding_dir, "gitora_icon.svg")
    create_gitora_icon_svg(svg_path)

    # 2. Generate PNG sizes
    sizes = [16, 24, 32, 48, 64, 128, 256, 512, 1024]
    rendered = {}
    for sz in sizes:
        img = render_raster_icon(sz)
        rendered[sz] = img
        out_png = os.path.join(branding_dir, f"icon_{sz}.png")
        img.save(out_png, "PNG")
        print(f"Generated {out_png}")

    # 3. Generate Windows ICO with multiple layers (16, 24, 32, 48, 64, 128, 256)
    ico_sizes = [16, 24, 32, 48, 64, 128, 256]
    ico_images = [rendered[s] for s in ico_sizes]
    
    branding_ico = os.path.join(branding_dir, "app_icon.ico")
    rendered[256].save(branding_ico, format="ICO", sizes=[(s, s) for s in ico_sizes])
    print(f"Generated {branding_ico}")

    # 4. Copy ICO to windows/runner/resources/app_icon.ico
    win_ico = os.path.join(base_dir, "windows", "runner", "resources", "app_icon.ico")
    rendered[256].save(win_ico, format="ICO", sizes=[(s, s) for s in ico_sizes])
    print(f"Updated Windows Runner ICO: {win_ico}")

    # 5. Copy Linux icons
    linux_dir = os.path.join(base_dir, "linux", "packaging")
    os.makedirs(linux_dir, exist_ok=True)
    rendered[512].save(os.path.join(linux_dir, "dev.skrinvex.gitora.png"), "PNG")
    create_gitora_icon_svg(os.path.join(linux_dir, "dev.skrinvex.gitora.svg"))
    print("Generated Linux packaging icons.")

if __name__ == "__main__":
    main()
