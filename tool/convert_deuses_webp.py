#!/usr/bin/env python3
"""
Script para converter os ícones das divindades de JPEG (736x736) para WebP (192x192).
Exibidos a 64px (3x = 192px para telas @3x retina/high-DPI).
Reduz o espaço em disco de ~1,7 MB para ~200 KB e a memória decodificada de ~2,1 MB para ~147 KB por deus.
"""

import os
from PIL import Image

def main():
    icons_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icons', 'deuses')
    icons_dir = os.path.abspath(icons_dir)

    total_orig = 0
    total_new = 0
    count = 0

    print(f"Processando imagens em: {icons_dir}")

    for filename in sorted(os.listdir(icons_dir)):
        if filename.lower().endswith(('.jpeg', '.jpg')):
            src_path = os.path.join(icons_dir, filename)
            base_name = os.path.splitext(filename)[0]
            dst_path = os.path.join(icons_dir, f"{base_name}.webp")

            orig_size = os.path.getsize(src_path)
            total_orig += orig_size

            with Image.open(src_path) as img:
                # Converte para RGB caso esteja em outro modo
                if img.mode != 'RGB':
                    img = img.convert('RGB')
                resized = img.resize((192, 192), Image.Resampling.LANCZOS)
                resized.save(dst_path, 'WEBP', quality=85, method=6)

            new_size = os.path.getsize(dst_path)
            total_new += new_size
            count += 1

            # Remove o JPEG original
            os.remove(src_path)

            print(f"  {filename} ({orig_size // 1024} KB) -> {base_name}.webp ({new_size // 1024} KB)")

    print(f"\nConcluído: {count} imagens processadas.")
    print(f"Tamanho total original: {total_orig / 1024:.1f} KB")
    print(f"Tamanho total WebP:     {total_new / 1024:.1f} KB")
    print(f"Economia em disco:      {(1 - total_new / total_orig) * 100:.1f}%")

if __name__ == '__main__':
    main()
