from __future__ import annotations

import base64
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "Fixtures"


def write_txt_fixtures() -> None:
    target = FIXTURES / "TXT"
    target.mkdir(parents=True, exist_ok=True)
    sample = "Gridnote offline fixture\n\nThis text is safe for parser and reading tests.\n"
    (target / "utf8-sample.txt").write_text(sample, encoding="utf-8")
    (target / "utf16-sample.txt").write_text(sample, encoding="utf-16")
    (target / "gb18030-sample.txt").write_bytes("离线测试文本\n\n用于验证 GB18030 解码。\n".encode("gb18030"))

    line = "Gridnote large-file performance fixture. This line contains no copyrighted text.\n"
    encoded = line.encode("utf-8")
    size = 20 * 1024 * 1024
    repeats, remainder = divmod(size, len(encoded))
    (target / "large-20mb.txt").write_bytes(encoded * repeats + encoded[:remainder])


def write_epub(path: Path, include_image: bool) -> None:
    image_item = '<item id="image" href="pixel.png" media-type="image/png"/>' if include_image else ""
    image_tag = '<img src="pixel.png" alt="fixture"/>' if include_image else ""
    package = f'''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:identifier id="id">gridnote-fixture</dc:identifier><dc:title>Gridnote Fixture</dc:title><dc:creator>Gridnote Tests</dc:creator><dc:language>en</dc:language></metadata>
  <manifest><item id="chapter" href="chapter.xhtml" media-type="application/xhtml+xml"/><item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>{image_item}</manifest>
  <spine><itemref idref="chapter"/></spine>
</package>'''
    container = '''<?xml version="1.0"?><container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0"><rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>'''
    chapter = f'''<?xml version="1.0"?><html xmlns="http://www.w3.org/1999/xhtml"><head><title>Fixture Chapter</title></head><body><h1>Fixture Chapter</h1><p>Offline EPUB parser sample.</p>{image_tag}</body></html>'''
    nav = '''<?xml version="1.0"?><html xmlns="http://www.w3.org/1999/xhtml"><body><nav><ol><li><a href="chapter.xhtml">Fixture Chapter</a></li></ol></nav></body></html>'''
    pixel = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")

    with zipfile.ZipFile(path, "w") as archive:
        archive.writestr("mimetype", "application/epub+zip", compress_type=zipfile.ZIP_STORED)
        archive.writestr("META-INF/container.xml", container)
        archive.writestr("OEBPS/content.opf", package)
        archive.writestr("OEBPS/chapter.xhtml", chapter)
        archive.writestr("OEBPS/nav.xhtml", nav)
        if include_image:
            archive.writestr("OEBPS/pixel.png", pixel)


def write_epub_fixtures() -> None:
    target = FIXTURES / "EPUB"
    target.mkdir(parents=True, exist_ok=True)
    write_epub(target / "basic-with-toc.epub", include_image=False)
    write_epub(target / "basic-with-images.epub", include_image=True)
    (target / "corrupted.epub").write_bytes(b"not an epub archive")


if __name__ == "__main__":
    write_txt_fixtures()
    write_epub_fixtures()
    print(f"Fixtures written to {FIXTURES}")
