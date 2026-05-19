"""Convert the APIs alteradas markdown to a self-contained HTML for PDF rendering."""
import sys
from pathlib import Path
import markdown

ROOT = Path(__file__).parent
MD_PATH = ROOT / "2026-05-13-cnpj-alfanumerico-apis-alteradas.md"
HTML_PATH = ROOT / "2026-05-13-cnpj-alfanumerico-apis-alteradas.html"

CSS = """
  body { font-family: 'Segoe UI', Arial, sans-serif; font-size: 11pt; color: #222; max-width: 900px; margin: 2em auto; padding: 0 1.5em; line-height: 1.5; }
  h1 { color: #1a3a5c; border-bottom: 2px solid #1a3a5c; padding-bottom: 0.3em; page-break-before: auto; }
  h2 { color: #1a3a5c; border-bottom: 1px solid #ccc; padding-bottom: 0.2em; margin-top: 1.5em; page-break-before: auto; }
  h2:first-of-type { page-break-before: avoid; }
  h3 { color: #2a5a8c; margin-top: 1.2em; }
  h4 { color: #3a6a9c; }
  table { border-collapse: collapse; width: 100%; margin: 1em 0; font-size: 10pt; }
  th, td { border: 1px solid #bbb; padding: 0.4em 0.7em; text-align: left; vertical-align: top; }
  th { background: #e8eef5; font-weight: 600; }
  tr:nth-child(even) td { background: #f7f9fb; }
  code { background: #f0f0f0; padding: 0.1em 0.3em; border-radius: 3px; font-size: 90%; font-family: 'Consolas', 'Courier New', monospace; }
  pre { background: #f5f5f5; padding: 0.8em; border-left: 3px solid #1a3a5c; overflow-x: auto; }
  pre code { background: transparent; padding: 0; }
  blockquote { border-left: 3px solid #aac; margin-left: 0; padding-left: 1em; color: #555; }
  hr { border: none; border-top: 1px solid #ccc; margin: 2em 0; }
  ul, ol { padding-left: 1.5em; }
  li { margin: 0.2em 0; }
  strong { color: #1a3a5c; }
  @page { size: A4; margin: 1.5cm; }
"""

md_text = MD_PATH.read_text(encoding="utf-8")
html_body = markdown.markdown(md_text, extensions=["tables", "fenced_code", "toc"])

html = f"""<!DOCTYPE html>
<html lang='pt-BR'>
<head>
<meta charset='UTF-8'>
<title>CNPJ Alfanumerico - APIs Alteradas</title>
<style>{CSS}</style>
</head>
<body>
{html_body}
</body>
</html>
"""

HTML_PATH.write_text(html, encoding="utf-8")
print(f"OK -> {HTML_PATH}")
