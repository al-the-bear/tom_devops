/// Wrapper classes for PDF converter options.
///
/// These wrappers expose PDF converter options using simple types that can be
/// easily bridged to D4rt without external package dependencies.
library;

import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'md_pdf_converter.dart';

/// Page format options for PDF generation.
/// 
/// This wrapper provides string-based access to common page formats,
/// avoiding the need to bridge the `PdfPageFormat` class directly.
enum PageFormat {
  a3,
  a4,
  a5,
  letter,
  legal,
  tabloid;

  /// Converts to the underlying PdfPageFormat.
  PdfPageFormat toPdfPageFormat() {
    switch (this) {
      case PageFormat.a3:
        return PdfPageFormat.a3;
      case PageFormat.a4:
        return PdfPageFormat.a4;
      case PageFormat.a5:
        return PdfPageFormat.a5;
      case PageFormat.letter:
        return PdfPageFormat.letter;
      case PageFormat.legal:
        return PdfPageFormat.legal;
      case PageFormat.tabloid:
        return PdfPageFormat(279.4 * PdfPageFormat.mm, 431.8 * PdfPageFormat.mm);
    }
  }
  
  /// Creates from string name.
  static PageFormat fromString(String name) {
    return PageFormat.values.firstWhere(
      (f) => f.name.toLowerCase() == name.toLowerCase(),
      orElse: () => PageFormat.a4,
    );
  }
}

/// Wrapper for PDF page margins using simple numeric values.
class PageMargins {
  /// Top margin in points.
  final double top;
  
  /// Right margin in points.
  final double right;
  
  /// Bottom margin in points.
  final double bottom;
  
  /// Left margin in points.
  final double left;
  
  /// Creates page margins.
  const PageMargins({
    this.top = 72.0,
    this.right = 72.0,
    this.bottom = 72.0,
    this.left = 72.0,
  });
  
  /// Creates uniform margins (all sides equal).
  const PageMargins.all(double value)
      : top = value,
        right = value,
        bottom = value,
        left = value;
  
  /// Creates symmetric margins.
  const PageMargins.symmetric({
    double horizontal = 72.0,
    double vertical = 72.0,
  })  : top = vertical,
        right = horizontal,
        bottom = vertical,
        left = horizontal;
  
  /// Converts to PDF EdgeInsets.
  pw.EdgeInsets toEdgeInsets() {
    return pw.EdgeInsets.only(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
    );
  }
}

/// D4rt-friendly wrapper for MdPdfConverterOptions.
/// 
/// This class provides a bridge-compatible interface that uses simple types
/// instead of external PDF package types.
class PdfConverterOptionsWrapper {
  /// Document title.
  final String? title;
  
  /// Document author.
  final String? author;
  
  /// Page format as string (a3, a4, a5, letter, legal, tabloid).
  final String pageFormat;
  
  /// Page margins.
  final PageMargins margins;
  
  /// Default font size in points.
  final double fontSize;
  
  /// Default font family.
  final String fontFamily;
  
  /// Patterns of files/directories to exclude.
  final List<String> excludePatterns;
  
  /// Creates PDF converter options wrapper.
  PdfConverterOptionsWrapper({
    this.title,
    this.author,
    this.pageFormat = 'a4',
    this.margins = const PageMargins.all(72),
    this.fontSize = 12.0,
    this.fontFamily = 'Roboto',
    this.excludePatterns = const ['node_modules', '.git', 'build'],
  });
  
  /// Converts to the underlying MdPdfConverterOptions.
  MdPdfConverterOptions toOptions() {
    return MdPdfConverterOptions(
      title: title,
      author: author,
      pageFormat: PageFormat.fromString(pageFormat).toPdfPageFormat(),
      margin: margins.toEdgeInsets(),
      fontSize: fontSize,
      fontFamily: fontFamily,
      excludePatterns: excludePatterns,
    );
  }
}
