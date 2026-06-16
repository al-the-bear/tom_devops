# Tom Md2Latex

> Tom Md2Latex is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in this package's license — see
> [LICENSE](LICENSE).

Markdown to LaTeX converter with PDF output support.

`tom_md2latex` turns Markdown into clean LaTeX — and optionally a typeset PDF —
with its **own** Markdown parser written in Dart. There is no pandoc dependency:
the Markdown→LaTeX step is pure Dart, and only the final, optional PDF pass shells
out to **XeLaTeX**. It is the converter the Tom devops toolchain uses to produce
reference PDFs from the workspace's Markdown docs.

> Need a PDF **without** a TeX install? Use the sibling
> [`tom_md2pdf`](../tom_md2pdf/) instead — it renders straight to PDF via
> `htmltopdfwidgets` with no system LaTeX. `tom_md2latex` is the choice when you
> want real LaTeX output (or LaTeX-quality typesetting) and have XeLaTeX
> available.

---

## Overview

The converter does two separable jobs:

| Stage | What happens | Needs |
| ----- | ------------ | ----- |
| **Markdown → LaTeX** | A Dart parser turns Markdown into a `.tex` document (or a fragment for inclusion). | Dart only — no external tools. |
| **LaTeX → PDF** *(optional, `--pdf`)* | XeLaTeX is run twice (so cross-references and the TOC resolve) to produce a `.pdf`. | XeLaTeX + a handful of LaTeX packages. |

Because the first stage is pure Dart, you can convert Markdown to LaTeX anywhere
Dart runs; you only need a TeX installation when you actually ask for a PDF.

### What it converts

- Headings, paragraphs, lists, tables, and inline formatting
- Fenced code blocks — syntax-highlighted via the `listings` package
- **ASCII diagrams** — auto-detected and rendered in a monospace, framed block
- Block quotes — rendered with framed styling
- A configurable table of contents (depth 1–5)
- YAML **frontmatter** — `title`, `author`, `date`, `toc`, `toc-depth`

---

## Installation

`tom_md2latex` is a **workspace-internal package** (`publish_to: none`). It is
not published to pub.dev; it is run from this package, which declares a single
executable, `md2latex`:

```bash
# Run via the package executable …
dart run tom_md2latex:md2latex <input> [options]

# … or compile it and put `md2latex` on your PATH.
dart compile exe bin/md_latex_converter.dart -o md2latex
```

**SDK requirement:** Dart `^3.10.4`. **Dart dependency:** `path` (only).

### System dependency (for `--pdf` only)

PDF generation shells out to **XeLaTeX** (from [TeX Live](https://tug.org/texlive/)
or MacTeX). The Markdown→LaTeX conversion needs none of this. The generated
preamble uses these LaTeX packages, all shipped with a standard TeX Live:

`fontspec` (Unicode fonts) · `listings` (code) · `framed` (quotes, ASCII
diagrams) · `booktabs` (tables) · `fancyvrb` (verbatim) · `graphicx` (images) ·
`hyperref` (links) · `xcolor` (colours).

```bash
# macOS
brew install --cask mactex        # or: brew install basictex
# Debian/Ubuntu
sudo apt-get install texlive-xetex texlive-latex-extra
```

---

## Quick start

Convert a Markdown file to LaTeX, in the same folder as the input:

```bash
dart run tom_md2latex:md2latex README.md
# → README.tex
```

Convert straight to PDF (runs XeLaTeX) and drop the intermediate `.tex`:

```bash
dart run tom_md2latex:md2latex README.md --pdf --no-tex
# → README.pdf
```

Convert an entire directory tree into an output folder, with a deep TOC:

```bash
dart run tom_md2latex:md2latex docs/ -o=build/tex --toc-depth=5
```

---

## Example projects

| Location | What it shows |
| -------- | ------------- |
| [`bin/md_latex_converter.dart`](bin/md_latex_converter.dart) | The full CLI — argument parsing, conversion, and the two-pass XeLaTeX PDF step. |
| `../tom_devops_samples/tom_md2pdf_sample/` | A runnable doc-conversion walkthrough covering both `md2latex` (LaTeX/PDF) and `md2pdf` (straight PDF) — see the [samples learning path](../README.md). *(forward reference — added later in this quest.)* |

---

## Usage

### Command line

```
dart run tom_md2latex:md2latex <input> [options]
```

`<input>` is a Markdown file or a directory (converted recursively).

| Option | Effect |
| ------ | ------ |
| `-o`, `--output=DIR` | Output directory (default: same folder as the input). |
| `--pdf` | Also generate a PDF via XeLaTeX (two passes). |
| `--no-tex` | Delete the `.tex` (and aux files) after the PDF is produced. |
| `--no-preamble` | Emit a LaTeX **fragment** (no preamble) for `\input` into another document. |
| `--document-class=CLASS` | LaTeX document class (default: `article`). |
| `--author=NAME` | Document author metadata. |
| `--no-ascii` | Disable ASCII-diagram detection. |
| `--no-toc` | Disable the table of contents. |
| `--toc-depth=N` | TOC depth, 1–5 (default: 3 → down to subsubsections). |
| `-h`, `--help` | Show usage. |

### Frontmatter

YAML frontmatter in the source overrides the document defaults:

```markdown
---
title: "My Document"
author: "Ada Lovelace"
date: "2026-06-17"
toc: true
toc-depth: 3
---

# First heading
```

### Library API

The same conversion is available programmatically through the static `Md2Latex`
façade — handy in build scripts:

```dart
import 'package:tom_md2latex/tom_md2latex.dart';

void main() async {
  // String → LaTeX string (full document by default).
  final tex = Md2Latex.convertString(
    markdown: '# Hello\n\nWorld.',
    author: 'Ada Lovelace',
  );

  // File → .tex on disk.
  final file = await Md2Latex.convertFile(inputPath: 'README.md');
  print('Wrote ${file.outputPath}');

  // Whole directory → output folder, with statistics.
  final result = await Md2Latex.convertDirectory(
    inputDir: 'docs',
    outputDir: 'build/tex',
  );
  print('Converted ${result.converted.length}, '
      'errors ${result.errors.length}');
}
```

For a fragment to embed in a larger document, pass `generatePreamble: false`
(or use `Md2Latex.convertFileToString` / `convertFileToStringSync` to get the
LaTeX back without writing a file).

For finer control, construct an `MdLatexConverter` directly with an
`MdLatexConverterOptions`:

```dart
final converter = MdLatexConverter(
  'docs',
  options: const MdLatexConverterOptions(
    documentClass: 'report',
    generateToc: true,
    tocDepth: 4,
    parserOptions: MarkdownParserOptions(detectAsciiDiagrams: true),
  ),
);
final result = await converter.convertAll(outputDir: 'build/tex');
```

---

## Architecture

```
        md_latex_converter.dart (CLI)
                  │ parses flags, optionally runs XeLaTeX
                  ▼
        Md2Latex (static façade)  ──▶  MdLatexConverter
                                            │
                          ┌─────────────────┼─────────────────┐
                          ▼                 ▼                 ▼
                  MarkdownParser        LatexMacros      MdLatexConverterOptions
                  → ParsedMarkdown      (preamble)       (class, toc, author…)
                    (+ element types)
                          │
                          ▼
                  .tex  ──(--pdf)──▶  XeLaTeX × 2  ──▶  .pdf
```

### Key types

| Type | Role |
| ---- | ---- |
| `Md2Latex` | Static façade — `convertString`, `convertFile`, `convertFileToString`, `convertFileToStringSync`, `convertDirectory`. |
| `MdLatexConverter` | The engine — `convert(string)`, `convertFile`, `convertAll`, `findMarkdownFiles`. |
| `MdLatexConverterOptions` | Conversion options — `documentClass`, `author`, `generatePreamble`, `generateToc`, `tocDepth`, `excludePatterns`, `parserOptions`. |
| `MdLatexConverterResult` | Batch result — `converted`, `errors`, `isSuccess`, `totalProcessed`. |
| `ConvertedFile` / `ConversionError` | Per-file success / failure records. |
| `MarkdownParser` / `MarkdownParserOptions` | The Markdown parser and its ASCII-diagram detection settings. |
| `ParsedMarkdown` | Parsed document — `title`, `author`, `date`, `generateToc`, `tocDepth`, `elements`. |
| `HeadingElement`, `ParagraphElement`, `CodeBlockElement`, `InlineCodeElement`, `TableElement`, … | The parsed Markdown element model. |
| `LatexMacros` | Generates the LaTeX preamble (packages, fonts, listings/framed styling). |

---

## Ecosystem

```
        Markdown docs
              │
   ┌──────────┴───────────┐
   ▼                      ▼
tom_md2latex          tom_md2pdf
(LaTeX, opt. PDF      (PDF via
 via XeLaTeX)          htmltopdfwidgets)
   │                      │
   ▼                      ▼
.tex / .pdf             .pdf
(needs TeX)            (no TeX needed)
```

`tom_md2latex` and `tom_md2pdf` are the two doc-conversion tools in the devops
toolchain. Reach for `tom_md2latex` when you want LaTeX output or LaTeX-quality
typesetting and have XeLaTeX; reach for `tom_md2pdf` when you want a PDF with no
system dependencies.

---

## Related packages

| Package | Relationship |
| ------- | ------------ |
| [`tom_md2pdf`](../tom_md2pdf/) | The no-LaTeX sibling — Markdown → PDF via `htmltopdfwidgets`. |
| [Tom DevOps map](../README.md) | The repository-level index for the whole devops toolchain. |

---

## Status

- **Version:** 1.0.0 (`publish_to: none` — workspace-internal)
- **SDK:** Dart `^3.10.4`
- **Dart dependency:** `path` (only).
- **System dependency:** XeLaTeX — **only** for `--pdf`; the Markdown→LaTeX
  stage is pure Dart and needs no external tools (no pandoc).
- **Executable:** `md2latex` (`bin/md_latex_converter.dart`).
- **Tests:** none yet — the package has no automated test suite at present.

---

## License

See [LICENSE](LICENSE); each package in this repository carries its own license
terms.
