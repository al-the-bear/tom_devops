# Tom Md2Pdf

> Tom Md2Pdf is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in this package's license — see
> [LICENSE](LICENSE).

Markdown to PDF converter using htmltopdfwidgets.

`tom_md2pdf` turns Markdown straight into a typeset **PDF** with **no system
LaTeX** and **no external tools**. The whole pipeline is pure Dart: Markdown is
rendered to PDF widgets by [`htmltopdfwidgets`](https://pub.dev/packages/htmltopdfwidgets)
and laid out by the [`pdf`](https://pub.dev/packages/pdf) package. If Dart runs,
it produces a PDF — there is nothing else to install.

> Need **real LaTeX** output, or LaTeX-quality typesetting? Use the sibling
> [`tom_md2latex`](../tom_md2latex/) instead — it emits `.tex` and, optionally,
> a PDF via **XeLaTeX**. `tom_md2pdf` is the choice when you just want a PDF and
> don't want a TeX installation in the loop.

---

## Overview

`tom_md2pdf` does a single job, end to end, in one process:

| Stage | What happens | Needs |
| ----- | ------------ | ----- |
| **Markdown → PDF** | `htmltopdfwidgets` converts the Markdown into PDF widgets; the `pdf` package assembles them into a paginated document and saves the bytes. | Dart only — no external tools. |

Compare this with `tom_md2latex`, which separates *Markdown → LaTeX* (pure Dart)
from an optional *LaTeX → PDF* pass that shells out to XeLaTeX. `tom_md2pdf` has
no second stage and no system dependency: it goes from Markdown to PDF bytes in
a single Dart call.

### What it converts

- Headings, paragraphs, lists, tables, and inline formatting (bold, italic, code)
- Fenced code blocks
- Links and images
- Block quotes
- Multiple page formats (A3/A4/A5/Letter/Legal/Tabloid) and configurable margins
- Optional page-number footers and custom page headers/footers

### When to reach for which converter

```
            Markdown docs
                  │
       ┌──────────┴───────────┐
       ▼                      ▼
   tom_md2pdf             tom_md2latex
   (PDF via               (LaTeX, opt. PDF
    htmltopdfwidgets)      via XeLaTeX)
       │                      │
       ▼                      ▼
     .pdf                  .tex / .pdf
  (no TeX needed)         (needs TeX for --pdf)
```

Reach for `tom_md2pdf` when you want a PDF with **zero system dependencies**;
reach for `tom_md2latex` when you want **LaTeX output** or LaTeX-grade
typesetting and have XeLaTeX available.

---

## Installation

`tom_md2pdf` is a **workspace-internal package** (`publish_to: none`). It is not
published to pub.dev; it is run from this package, which declares a single
executable, `md2pdf`:

```bash
# Run via the package executable …
dart run tom_md2pdf:md2pdf <input> [options]

# … or compile it and put `md2pdf` on your PATH.
dart compile exe bin/md_pdf_converter.dart -o md2pdf
```

**SDK requirement:** Dart `^3.10.4`. **Dart dependencies:**
[`htmltopdfwidgets`](https://pub.dev/packages/htmltopdfwidgets) (Markdown → PDF
widgets), [`pdf`](https://pub.dev/packages/pdf) (document layout), and
[`path`](https://pub.dev/packages/path). **No system dependency** — there is no
LaTeX, no pandoc, and nothing to install beyond the Dart packages.

---

## Quick start

Convert a Markdown file to a PDF in the same folder as the input:

```bash
dart run tom_md2pdf:md2pdf README.md
# → README.pdf
```

Convert into a specific output directory, with an author and page numbers:

```bash
dart run tom_md2pdf:md2pdf README.md -o=build/pdf --author="Ada Lovelace" --page-numbers
# → build/pdf/README.pdf
```

Convert an entire directory tree (recursively) into an output folder:

```bash
dart run tom_md2pdf:md2pdf docs/ -o=build/pdf --format=letter
# → build/pdf/<each .md>.pdf
```

---

## Example projects

| Location | What it shows |
| -------- | ------------- |
| [`bin/md_pdf_converter.dart`](bin/md_pdf_converter.dart) | The full CLI — argument parsing, page-format/margin/font options, page-number footers, and batch directory conversion. |
| `../tom_devops_samples/tom_md2pdf_sample/` | A runnable doc-conversion walkthrough covering both `md2pdf` (straight PDF) and `md2latex` (LaTeX/PDF) — see the [samples learning path](../README.md). *(forward reference — added later in this quest.)* |

---

## Usage

### Command line

```
dart run tom_md2pdf:md2pdf <input> [options]
```

`<input>` is a Markdown file or a directory (converted recursively). The
executable is `md2pdf`; its source is [`bin/md_pdf_converter.dart`](bin/md_pdf_converter.dart).

| Option | Effect |
| ------ | ------ |
| `-o`, `--output=DIR` | Output directory (default: same folder as the input). |
| `--title=TITLE` | Document title metadata (defaults to the file's base name). |
| `--author=NAME` | Document author metadata. |
| `--format=FORMAT` | Page format: `a4` (default), `a3`, `a5`, `letter`, `legal`. |
| `--margin=POINTS` | Uniform page margin in points (default: `72` = 1 inch). |
| `--font-size=POINTS` | Default font size in points (default: `12`). |
| `--page-numbers` | Add a `Page N of M` footer to every page. |
| `--no-default-styles` | Disable the built-in HTML tag styling (paragraph margins, headings). |
| `-h`, `--help` | Show usage. |

### Library API

The same conversion is available programmatically through the static `Md2Pdf`
façade — handy in build scripts. Every parameter uses simple types (strings,
numbers) so the API bridges cleanly into D4rt scripts:

```dart
import 'dart:io';
import 'package:tom_md2pdf/tom_md2pdf.dart';

void main() async {
  // Markdown string → PDF bytes (write them yourself).
  final bytes = await Md2Pdf.convertString(
    markdown: '# Hello\n\nWorld.',
    author: 'Ada Lovelace',
  );
  File('hello.pdf').writeAsBytesSync(bytes);

  // File → .pdf on disk; returns the source/output paths.
  final file = await Md2Pdf.convertFile(inputPath: 'README.md');
  print('Wrote ${file.outputPath}');           // Wrote README.pdf

  // Whole directory → output folder, with statistics.
  final result = await Md2Pdf.convertDirectory(
    inputDir: 'docs',
    outputDir: 'build/pdf',
  );
  print('Converted ${result.converted.length}, '
      'errors ${result.errors.length}');
}
```

The façade also offers `convertFileToBytes` (read a file, return PDF bytes
without writing) and `convertFileAndSave` (convert and write to an explicit
output path, returning `true` on success).

### Page format and margins (D4rt-friendly wrappers)

`Md2Pdf` takes page format as a string and margins as a `PageMargins` value, so
no `pdf`-package types leak into a script:

```dart
final bytes = await Md2Pdf.convertString(
  markdown: '# Report',
  pageFormat: 'letter',
  margins: const PageMargins.symmetric(horizontal: 54, vertical: 72),
  fontSize: 11,
);
```

`PageFormat` (`a3`, `a4`, `a5`, `letter`, `legal`, `tabloid`) and
`PageMargins` (`.all`, `.symmetric`, or per-side) are the wrapper types backing
those string/number arguments.

### Direct engine control

For finer control — custom page headers/footers, an explicit `tagStyle`, or
exclusion patterns — construct an `MdPdfConverter` directly with an
`MdPdfConverterOptions`:

```dart
import 'package:pdf/pdf.dart';
import 'package:tom_md2pdf/tom_md2pdf.dart';

final converter = MdPdfConverter(
  'docs',
  options: MdPdfConverterOptions(
    pageFormat: PdfPageFormat.a4,
    fontSize: 11,
    author: 'Tom DevOps',
    excludePatterns: const ['node_modules', '.git', 'build'],
  ),
);
final result = await converter.convertAll(outputDir: 'build/pdf');
print('Success: ${result.isSuccess}');
```

`MdPdfConverter` also exposes `findMarkdownFiles()`, `convertFile(file)`, and
`convertString(markdown)` if you want to drive the steps yourself.

---

## Architecture

```
        md_pdf_converter.dart (CLI)
                  │ parses flags, builds options
                  ▼
        Md2Pdf (static façade)  ──▶  MdPdfConverter
              │ simple-typed args        │ engine
              ▼                          ▼
   PageFormat / PageMargins /      htmltopdfwidgets  ──▶  PDF widgets
   PdfConverterOptionsWrapper            │
   (D4rt-friendly)                       ▼
                                  pdf package (pw.Document)
                                         │
                                         ▼
                                       .pdf bytes
```

### Key types

| Type | Role |
| ---- | ---- |
| `Md2Pdf` | Static façade — `convertString`, `convertFile`, `convertFileToBytes`, `convertDirectory`, `convertFileAndSave`. |
| `MdPdfConverter` | The engine — `findMarkdownFiles`, `convertAll`, `convertFile`, `convertString`. |
| `MdPdfConverterOptions` | Full conversion options — `title`, `author`, `pageFormat` (`PdfPageFormat`), `margin` (`pw.EdgeInsets`), `fontSize`, `fontFamily`, `tagStyle` (`HtmlTagStyle`), `excludePatterns`, `headerBuilder`, `footerBuilder`. |
| `MdPdfConverterResult` | Batch result — `converted`, `errors`, `isSuccess`. |
| `PdfConvertedFile` / `PdfConversionError` | Per-file success / failure records. |
| `PdfConverterOptionsWrapper` | D4rt-friendly options that use simple types (string page format, numeric margins) and convert to `MdPdfConverterOptions`. |
| `PageFormat` | String-named page formats (`a3`, `a4`, `a5`, `letter`, `legal`, `tabloid`) → `PdfPageFormat`. |
| `PageMargins` | Numeric margins (`.all`, `.symmetric`, per-side) → `pw.EdgeInsets`. |

---

## Ecosystem

```
        Markdown docs
              │
   ┌──────────┴───────────┐
   ▼                      ▼
tom_md2pdf            tom_md2latex
(PDF via               (LaTeX, opt. PDF
 htmltopdfwidgets)      via XeLaTeX)
   │                      │
   ▼                      ▼
.pdf                   .tex / .pdf
(no TeX needed)        (needs TeX)
```

`tom_md2pdf` and `tom_md2latex` are the two doc-conversion tools in the devops
toolchain. Reach for `tom_md2pdf` when you want a PDF with no system
dependencies; reach for `tom_md2latex` when you want LaTeX output or
LaTeX-quality typesetting and have XeLaTeX.

---

## Related packages

| Package | Relationship |
| ------- | ------------ |
| [`tom_md2latex`](../tom_md2latex/) | The LaTeX sibling — Markdown → LaTeX, optional PDF via XeLaTeX. |
| [Tom DevOps map](../README.md) | The repository-level index for the whole devops toolchain. |

---

## Status

- **Version:** 1.0.0 (`publish_to: none` — workspace-internal)
- **SDK:** Dart `^3.10.4`
- **Dart dependencies:** `htmltopdfwidgets`, `pdf`, `path`.
- **System dependency:** none — pure Dart; no LaTeX, no pandoc, no external tools.
- **Executable:** `md2pdf` (`bin/md_pdf_converter.dart`).
- **Tests:** none yet — the package has no automated test suite at present.

---

## License

See [LICENSE](LICENSE); each package in this repository carries its own license
terms.
