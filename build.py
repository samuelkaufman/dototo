#!/usr/bin/env python3
"""Build script: injects .glsl shader files into template.html -> dist/index.html"""
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SHADER_DIR = os.path.join(ROOT, 'src', 'shaders')
TEMPLATE = os.path.join(ROOT, 'src', 'template.html')
OUT_DIR = os.path.join(ROOT, 'dist')
OUT_FILE = os.path.join(OUT_DIR, 'index.html')

with open(TEMPLATE) as f:
    html = f.read()

for name in sorted(os.listdir(SHADER_DIR)):
    if not name.endswith('.glsl'):
        continue
    # presence.vert.glsl -> __PRESENCE_VERT__
    placeholder = '__' + name.replace('.glsl', '').replace('.', '_').upper() + '__'
    with open(os.path.join(SHADER_DIR, name)) as f:
        src = f.read()

    if placeholder not in html:
        print(f'  Warning: {placeholder} not found in template', file=sys.stderr)
        continue

    html = html.replace(placeholder, src)
    print(f'  {name} -> {placeholder}')

os.makedirs(OUT_DIR, exist_ok=True)
with open(OUT_FILE, 'w') as f:
    f.write(html)

print(f'\nBuilt {OUT_FILE}')
