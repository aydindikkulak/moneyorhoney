#!/usr/bin/env python3
"""
Money or Honey - Pixel Art Asset Generator
Generates consistent pixel art assets for the game
"""

from PIL import Image, ImageDraw, ImageFont
import os
import random

# Asset directories
ASSETS_DIR = "../assets/sprites"
CURRENCIES_DIR = f"{ASSETS_DIR}/currencies"
NPCS_DIR = f"{ASSETS_DIR}/npcs"
UI_DIR = f"{ASSETS_DIR}/ui"
TOOLS_DIR = f"{ASSETS_DIR}/tools"
DOCUMENTS_DIR = f"{ASSETS_DIR}/documents"

# Create directories
for dir_path in [CURRENCIES_DIR, NPCS_DIR, UI_DIR, TOOLS_DIR, DOCUMENTS_DIR]:
    os.makedirs(dir_path, exist_ok=True)
    os.makedirs(f"{dir_path}/usd", exist_ok=True)
    os.makedirs(f"{dir_path}/eur", exist_ok=True)
    os.makedirs(f"{dir_path}/gbp", exist_ok=True)

# Color palettes
COLORS = {
    "usd": {
        "primary": (74, 93, 35),      # Dark green
        "secondary": (139, 149, 86),  # Light green
        "accent": (45, 58, 15),       # Very dark green
        "text": (200, 220, 180),      # Light text
    },
    "eur": {
        "primary": (61, 90, 128),     # Blue
        "secondary": (152, 193, 217), # Light blue
        "accent": (41, 50, 65),       # Dark blue
        "text": (200, 220, 240),      # Light text
    },
    "gbp": {
        "primary": (107, 66, 38),     # Brown
        "secondary": (166, 124, 82),  # Light brown
        "accent": (61, 40, 23),       # Dark brown
        "text": (220, 200, 180),      # Light text
    }
}

def draw_pixel_border(draw, x, y, width, height, color, thickness=1):
    """Draw a pixel-perfect border"""
    for i in range(thickness):
        draw.rectangle([x+i, y+i, x+width-i-1, y+height-i-1], outline=color)

def draw_pixel_text(draw, x, y, text, color, font_size=8):
    """Draw pixel-style text (simplified)"""
    # Simple pixel font simulation
    char_width = font_size
    for i, char in enumerate(text):
        if char != ' ':
            draw.rectangle([x + i*char_width, y, x + i*char_width + char_width-2, y + font_size], fill=color)

def generate_banknote(currency, denomination, is_fake=False, size=(256, 128)):
    """Generate a banknote sprite"""
    img = Image.new('RGB', size, (0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    colors = COLORS[currency]
    
    # Background
    bg_color = colors["primary"]
    if is_fake:
        # Slightly different color for fake notes
        bg_color = tuple(min(255, c + random.randint(-15, 15)) for c in bg_color)
    
    draw.rectangle([0, 0, size[0]-1, size[1]-1], fill=bg_color)
    
    # Border
    border_color = colors["accent"]
    draw_pixel_border(draw, 4, 4, size[0]-8, size[1]-8, border_color, 2)
    
    # Inner decorative border
    inner_color = colors["secondary"]
    draw_pixel_border(draw, 8, 8, size[0]-16, size[1]-16, inner_color, 1)
    
    # Denomination (large number)
    denom_color = colors["text"]
    denom_text = str(denomination)
    
    # Draw denomination in corners
    corner_size = 20
    for corner_x, corner_y in [(12, 12), (size[0]-32, 12), (12, size[1]-32), (size[0]-32, size[1]-32)]:
        draw.rectangle([corner_x, corner_y, corner_x+corner_size, corner_y+corner_size], fill=denom_color)
        draw.rectangle([corner_x+2, corner_y+2, corner_x+corner_size-2, corner_y+corner_size-2], fill=bg_color)
    
    # Center portrait area (simplified oval)
    center_x, center_y = size[0]//2, size[1]//2
    portrait_width, portrait_height = 60, 80
    draw.ellipse([center_x-portrait_width//2, center_y-portrait_height//2,
                  center_x+portrait_width//2, center_y+portrait_height//2],
                 fill=colors["secondary"])
    draw.ellipse([center_x-portrait_width//2+4, center_y-portrait_height//2+4,
                  center_x+portrait_width//2-4, center_y+portrait_height//2-4],
                 fill=bg_color)
    
    # Add some decorative lines
    for i in range(5):
        y_pos = 20 + i * 20
        draw.line([(40, y_pos), (80, y_pos)], fill=colors["secondary"], width=1)
        draw.line([(size[0]-80, y_pos), (size[0]-40, y_pos)], fill=colors["secondary"], width=1)
    
    # Currency symbol
    symbol_map = {"usd": "$", "eur": "€", "gbp": "£"}
    symbol = symbol_map.get(currency, "$")
    
    # Draw symbol in center
    symbol_size = 30
    draw.rectangle([center_x-symbol_size//2, center_y-symbol_size//2,
                    center_x+symbol_size//2, center_y+symbol_size//2],
                   fill=denom_color)
    
    # Security features (for real notes)
    if not is_fake:
        # Hologram strip
        hologram_color = (200, 200, 255, 128)
        draw.rectangle([size[0]-50, 20, size[0]-40, size[1]-20], fill=(180, 180, 220))
        
        # Watermark area
        draw.ellipse([size[0]-100, size[1]-60, size[0]-60, size[1]-30],
                     fill=(*colors["secondary"][:3],))
    
    # Fake indicators (subtle differences)
    if is_fake:
        # Slightly misaligned elements
        draw.rectangle([15, 15, 25, 25], fill=(255, 0, 0, 50))  # Tiny red mark
    
    # Add noise/texture
    pixels = img.load()
    for _ in range(size[0] * size[1] // 10):
        x = random.randint(0, size[0]-1)
        y = random.randint(0, size[1]-1)
        r, g, b = pixels[x, y]
        noise = random.randint(-10, 10)
        pixels[x, y] = (max(0, min(255, r+noise)),
                        max(0, min(255, g+noise)),
                        max(0, min(255, b+noise)))
    
    return img

def generate_npc_sprite(npc_type="normal", size=(64, 64)):
    """Generate NPC character sprite"""
    img = Image.new('RGB', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Color schemes for different NPC types
    color_schemes = {
        "normal": {"skin": (220, 180, 150), "shirt": (100, 120, 140), "hair": (60, 40, 30)},
        "careless": {"skin": (210, 170, 140), "shirt": (140, 100, 120), "hair": (80, 60, 40)},
        "suspicious": {"skin": (200, 160, 130), "shirt": (80, 80, 80), "hair": (40, 40, 40)},
        "professional": {"skin": (230, 190, 160), "shirt": (60, 60, 80), "hair": (50, 30, 20)},
    }
    
    colors = color_schemes.get(npc_type, color_schemes["normal"])
    
    # Head
    head_x, head_y = size[0]//2, 20
    head_radius = 12
    draw.ellipse([head_x-head_radius, head_y-head_radius,
                  head_x+head_radius, head_y+head_radius],
                 fill=colors["skin"])
    
    # Hair
    draw.arc([head_x-head_radius, head_y-head_radius-4,
              head_x+head_radius, head_y+head_radius-4],
             180, 360, fill=colors["hair"], width=4)
    
    # Body
    body_x, body_y = size[0]//2, 45
    draw.rectangle([body_x-15, body_y, body_x+15, body_y+15],
                   fill=colors["shirt"])
    
    # Arms
    draw.rectangle([body_x-20, body_y+2, body_x-15, body_y+12],
                   fill=colors["shirt"])
    draw.rectangle([body_x+15, body_y+2, body_x+20, body_y+12],
                   fill=colors["shirt"])
    
    # Legs
    draw.rectangle([body_x-10, body_y+15, body_x-3, body_y+28],
                   fill=(60, 60, 80))
    draw.rectangle([body_x+3, body_y+15, body_x+10, body_y+28],
                   fill=(60, 60, 80))
    
    # Face details
    # Eyes
    draw.rectangle([head_x-5, head_y-2, head_x-3, head_y], fill=(40, 40, 40))
    draw.rectangle([head_x+3, head_y-2, head_x+5, head_y], fill=(40, 40, 40))
    
    # Mouth (different for different types)
    if npc_type == "suspicious":
        draw.line([head_x-3, head_y+5, head_x+3, head_y+5], fill=(40, 40, 40), width=1)
    elif npc_type == "professional":
        draw.arc([head_x-4, head_y+3, head_x+4, head_y+7], 0, 180, fill=(40, 40, 40), width=1)
    else:
        draw.line([head_x-2, head_y+5, head_x+2, head_y+5], fill=(40, 40, 40), width=1)
    
    return img

def generate_tool_icon(tool_name, size=(32, 32)):
    """Generate tool icons"""
    img = Image.new('RGB', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    if tool_name == "magnifier":
        # Magnifying glass
        draw.ellipse([4, 4, 20, 20], outline=(200, 200, 200), width=2)
        draw.ellipse([6, 6, 18, 18], outline=(150, 200, 255), width=1)
        draw.line([18, 18, 28, 28], fill=(150, 100, 50), width=3)
    
    elif tool_name == "uv_lamp":
        # UV lamp
        draw.rectangle([8, 8, 24, 20], fill=(100, 50, 150))
        draw.rectangle([10, 10, 22, 18], fill=(150, 100, 200))
        draw.rectangle([12, 20, 20, 26], fill=(80, 80, 80))
        # UV rays
        for i in range(3):
            draw.line([12+i*4, 8, 12+i*4, 4], fill=(200, 150, 255), width=1)
    
    elif tool_name == "scale":
        # Scale/balance
        draw.rectangle([14, 8, 18, 24], fill=(150, 150, 150))
        draw.polygon([(8, 12), (16, 8), (24, 12)], fill=(180, 180, 180))
        draw.ellipse([4, 12, 12, 20], outline=(120, 120, 120), width=2)
        draw.ellipse([20, 12, 28, 20], outline=(120, 120, 120), width=2)
    
    elif tool_name == "microscope":
        # Microscope
        draw.rectangle([12, 20, 20, 28], fill=(100, 100, 100))
        draw.rectangle([14, 8, 18, 20], fill=(150, 150, 150))
        draw.ellipse([10, 4, 22, 10], fill=(180, 180, 180))
        draw.rectangle([8, 28, 24, 30], fill=(80, 80, 80))
    
    return img

def generate_document_icon(doc_type, size=(64, 80)):
    """Generate document icons"""
    img = Image.new('RGB', size, (240, 240, 230))
    draw = ImageDraw.Draw(img)
    
    # Paper background
    draw.rectangle([0, 0, size[0]-1, size[1]-1], fill=(240, 240, 230))
    draw.rectangle([0, 0, size[0]-1, size[1]-1], outline=(180, 180, 170), width=1)
    
    # Header
    draw.rectangle([4, 4, size[0]-4, 12], fill=(100, 100, 120))
    
    # Text lines
    for i in range(6):
        y = 20 + i * 8
        width = random.randint(30, size[0]-16)
        draw.rectangle([8, y, 8+width, y+4], fill=(150, 150, 160))
    
    # Document type specific elements
    if doc_type == "invoice":
        # Dollar sign
        draw.rectangle([size[0]-20, 4, size[0]-8, 12], fill=(80, 120, 80))
    elif doc_type == "receipt":
        # Barcode
        for i in range(8):
            x = 8 + i * 6
            draw.rectangle([x, size[1]-16, x+4, size[1]-8], fill=(80, 80, 80))
    elif doc_type == "id":
        # Photo placeholder
        draw.rectangle([8, 20, 28, 40], fill=(180, 180, 190))
        draw.ellipse([12, 24, 24, 36], fill=(200, 180, 160))
    
    return img

def generate_ui_element(element_name, size=(32, 32)):
    """Generate UI elements"""
    img = Image.new('RGB', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    if element_name == "button_accept":
        draw.rectangle([0, 0, size[0]-1, size[1]-1], fill=(80, 160, 80))
        draw.rectangle([2, 2, size[0]-3, size[1]-3], outline=(100, 200, 100), width=1)
    elif element_name == "button_reject":
        draw.rectangle([0, 0, size[0]-1, size[1]-1], fill=(160, 80, 80))
        draw.rectangle([2, 2, size[0]-3, size[1]-3], outline=(200, 100, 100), width=1)
    elif element_name == "coin":
        draw.ellipse([4, 4, size[0]-4, size[1]-4], fill=(220, 180, 50))
        draw.ellipse([8, 8, size[0]-8, size[1]-8], outline=(180, 140, 30), width=2)
    elif element_name == "panel":
        draw.rectangle([0, 0, size[0]-1, size[1]-1], fill=(60, 70, 80))
        draw.rectangle([0, 0, size[0]-1, size[1]-1], outline=(100, 110, 120), width=2)
    
    return img

def main():
    print("Generating Money or Honey assets...")
    
    # Generate banknotes
    currencies = ["usd", "eur", "gbp"]
    denominations = {
        "usd": [1, 5, 10, 20, 50, 100],
        "eur": [5, 10, 20, 50, 100, 200, 500],
        "gbp": [5, 10, 20, 50]
    }
    
    for currency in currencies:
        for denom in denominations[currency]:
            # Real note
            img = generate_banknote(currency, denom, is_fake=False)
            img.save(f"{CURRENCIES_DIR}/{currency}/{currency}_{denom}_real.png")
            
            # Fake note
            img = generate_banknote(currency, denom, is_fake=True)
            img.save(f"{CURRENCIES_DIR}/{currency}/{currency}_{denom}_fake.png")
            
            print(f"Generated {currency} {denom} banknotes")
    
    # Generate NPCs
    npc_types = ["normal", "careless", "suspicious", "professional"]
    for npc_type in npc_types:
        for i in range(3):  # 3 variants per type
            img = generate_npc_sprite(npc_type)
            img.save(f"{NPCS_DIR}/npc_{npc_type}_{i}.png")
        print(f"Generated {npc_type} NPCs")
    
    # Generate tools
    tools = ["magnifier", "uv_lamp", "scale", "microscope"]
    for tool in tools:
        img = generate_tool_icon(tool)
        img.save(f"{TOOLS_DIR}/{tool}.png")
        print(f"Generated {tool} icon")
    
    # Generate documents
    doc_types = ["invoice", "receipt", "id"]
    for doc_type in doc_types:
        for i in range(3):
            img = generate_document_icon(doc_type)
            img.save(f"{DOCUMENTS_DIR}/{doc_type}_{i}.png")
        print(f"Generated {doc_type} documents")
    
    # Generate UI elements
    ui_elements = ["button_accept", "button_reject", "coin", "panel"]
    for element in ui_elements:
        img = generate_ui_element(element)
        img.save(f"{UI_DIR}/{element}.png")
        print(f"Generated {element} UI element")
    
    print("\nAsset generation complete!")
    print(f"Total assets generated:")
    print(f"- Banknotes: {sum(len(d) for d in denominations.values()) * 2} (real + fake)")
    print(f"- NPCs: {len(npc_types) * 3}")
    print(f"- Tools: {len(tools)}")
    print(f"- Documents: {len(doc_types) * 3}")
    print(f"- UI elements: {len(ui_elements)}")

if __name__ == "__main__":
    main()
