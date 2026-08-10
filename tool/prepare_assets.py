from __future__ import annotations

from pathlib import Path
import shutil

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

SOURCE_DIR = ROOT / "assets" / "source"
BRAND_DIR = ROOT / "assets" / "branding"
ICON_DIR = ROOT / "assets" / "icons"

LEGACY_SOURCES = {
    "launcher.png": ROOT / "assets" / "ChatGPT Image 10 août 2026, 02_18_48 (1).png",
    "brand_mark.png": ROOT / "assets" / "ChatGPT Image 10 août 2026, 02_18_49 (2).png",
    "nav_today.png": ROOT / "assets" / "ChatGPT Image 10 août 2026, 02_18_49 (3).png",
    "nav_history.png": ROOT / "assets" / "ChatGPT Image 10 août 2026, 02_18_50 (4).png",
    "nav_settings.png": ROOT / "assets" / "ChatGPT Image 10 août 2026, 02_18_50 (5).png",
    "dose_pills.png": ROOT / "assets" / "ChatGPT Image 10 août 2026, 02_18_50 (6).png",
    "dose_insulin_night.png": ROOT / "assets" / "ChatGPT Image 10 août 2026, 02_18_51 (7).png",
}


def ensure_sources() -> None:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    for clean_name, legacy_path in LEGACY_SOURCES.items():
        clean_path = SOURCE_DIR / clean_name
        if clean_path.exists():
            if legacy_path.exists():
                legacy_path.unlink()
            continue
        if not legacy_path.exists():
            raise FileNotFoundError(f"Missing icon source: {clean_name}")
        shutil.move(legacy_path, clean_path)


def trimmed_rgba(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    bounds = image.getchannel("A").getbbox()
    return image.crop(bounds) if bounds else image


def normalized(path: Path, size: int, padding: float) -> Image.Image:
    image = trimmed_rgba(path)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    content_size = round(size * (1 - (padding * 2)))
    scale = min(content_size / image.width, content_size / image.height)
    resized = image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.LANCZOS,
    )
    offset = ((size - resized.width) // 2, (size - resized.height) // 2)
    canvas.alpha_composite(resized, offset)
    return canvas


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def prepare_flutter_assets() -> None:
    BRAND_DIR.mkdir(parents=True, exist_ok=True)
    ICON_DIR.mkdir(parents=True, exist_ok=True)

    save_png(normalized(SOURCE_DIR / "brand_mark.png", 256, 0.10), BRAND_DIR / "dosecheck_mark.png")
    save_png(normalized(SOURCE_DIR / "nav_today.png", 128, 0.16), ICON_DIR / "nav_today.png")
    save_png(normalized(SOURCE_DIR / "nav_history.png", 128, 0.14), ICON_DIR / "nav_history.png")
    save_png(normalized(SOURCE_DIR / "nav_settings.png", 128, 0.15), ICON_DIR / "nav_settings.png")
    save_png(normalized(SOURCE_DIR / "dose_pills.png", 256, 0.12), ICON_DIR / "dose_pills.png")
    save_png(
        normalized(SOURCE_DIR / "dose_insulin_night.png", 256, 0.10),
        ICON_DIR / "dose_insulin_night.png",
    )


def launcher_rgb() -> Image.Image:
    return Image.open(SOURCE_DIR / "launcher.png").convert("RGB")


def prepare_android() -> None:
    launcher = launcher_rgb()
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in sizes.items():
        destination = res / folder
        save_png(launcher.resize((size, size), Image.Resampling.LANCZOS), destination / "ic_launcher.png")
        save_png(launcher.resize((size, size), Image.Resampling.LANCZOS), destination / "ic_launcher_round.png")

    save_png(
        normalized(SOURCE_DIR / "brand_mark.png", 432, 0.22),
        res / "drawable-nodpi" / "ic_launcher_foreground.png",
    )
    save_png(
        normalized(SOURCE_DIR / "brand_mark.png", 432, 0.24),
        res / "drawable-nodpi" / "ic_launcher_monochrome.png",
    )

    (res / "values").mkdir(parents=True, exist_ok=True)
    (res / "values" / "icon_colors.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="dosecheck_icon_background">#F8F4EC</color>\n'
        '</resources>\n',
        encoding="utf-8",
    )

    for folder, include_monochrome in (("mipmap-anydpi-v26", False), ("mipmap-anydpi-v33", True)):
        directory = res / folder
        directory.mkdir(parents=True, exist_ok=True)
        monochrome = (
            '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n'
            if include_monochrome
            else ""
        )
        xml = (
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/dosecheck_icon_background" />\n'
            '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
            f'{monochrome}'
            '</adaptive-icon>\n'
        )
        (directory / "ic_launcher.xml").write_text(xml, encoding="utf-8")
        (directory / "ic_launcher_round.xml").write_text(xml, encoding="utf-8")


def prepare_ios() -> None:
    launcher = launcher_rgb()
    directory = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    specs = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, size in specs.items():
        save_png(launcher.resize((size, size), Image.Resampling.LANCZOS), directory / name)


def prepare_macos() -> None:
    launcher = launcher_rgb()
    directory = ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for size in (16, 32, 64, 128, 256, 512, 1024):
        save_png(launcher.resize((size, size), Image.Resampling.LANCZOS), directory / f"app_icon_{size}.png")


def prepare_web() -> None:
    launcher = launcher_rgb()
    save_png(launcher.resize((32, 32), Image.Resampling.LANCZOS), ROOT / "web" / "favicon.png")
    icon_dir = ROOT / "web" / "icons"
    for name, size in {
        "Icon-192.png": 192,
        "Icon-512.png": 512,
        "Icon-maskable-192.png": 192,
        "Icon-maskable-512.png": 512,
    }.items():
        save_png(launcher.resize((size, size), Image.Resampling.LANCZOS), icon_dir / name)


def prepare_windows() -> None:
    launcher = launcher_rgb()
    path = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    path.parent.mkdir(parents=True, exist_ok=True)
    launcher.save(
        path,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


def main() -> None:
    ensure_sources()
    prepare_flutter_assets()
    prepare_android()
    prepare_ios()
    prepare_macos()
    prepare_web()
    prepare_windows()
    print("DoseCheck assets prepared.")


if __name__ == "__main__":
    main()
