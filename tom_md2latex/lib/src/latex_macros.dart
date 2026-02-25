/// LaTeX macros and helpers for Markdown conversion.
///
/// Provides a set of functions to generate LaTeX code for common
/// markdown elements, including custom macros for better formatting.
class LatexMacros {
  LatexMacros._();

  /// Generates a complete LaTeX preamble.
  static String preamble({
    String documentClass = 'article',
    String? title,
    String? author,
    String? date,
    int tocDepth = 3,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('\\documentclass[11pt,a4paper]{$documentClass}');
    buffer.writeln();
    buffer.writeln('% ============================================================');
    buffer.writeln('% Packages');
    buffer.writeln('% ============================================================');
    buffer.writeln('% Use fontspec for XeLaTeX/LuaLaTeX Unicode support');
    buffer.writeln('\\usepackage{fontspec}');
    buffer.writeln('\\usepackage[margin=1in]{geometry}');
    buffer.writeln('\\usepackage{hyperref}');
    buffer.writeln('\\usepackage{xcolor}');
    buffer.writeln('\\usepackage{listings}');
    buffer.writeln('\\usepackage{booktabs}');
    buffer.writeln('\\usepackage{tabularx}');
    buffer.writeln('\\usepackage{array}'); // For column formatting
    buffer.writeln('\\usepackage{graphicx}');
    buffer.writeln('\\usepackage{fancyvrb}');
    buffer.writeln('\\usepackage{framed}'); // For block quotes and boxes
    buffer.writeln('\\usepackage{enumitem}');
    buffer.writeln('\\usepackage{parskip}');
    buffer.writeln();
    buffer.writeln('% ============================================================');
    buffer.writeln('% Custom Colors');
    buffer.writeln('% ============================================================');
    buffer.writeln('\\definecolor{codebackground}{RGB}{248,248,248}');
    buffer.writeln('\\definecolor{codeborder}{RGB}{220,220,220}');
    buffer.writeln('\\definecolor{codestring}{RGB}{163,21,21}');
    buffer.writeln('\\definecolor{codekeyword}{RGB}{0,0,255}');
    buffer.writeln('\\definecolor{codecomment}{RGB}{0,128,0}');
    buffer.writeln('\\definecolor{linkcolor}{RGB}{0,102,204}');
    buffer.writeln('\\definecolor{quotebackground}{RGB}{245,245,245}');
    buffer.writeln('\\definecolor{quoteborder}{RGB}{200,200,200}');
    buffer.writeln('\\definecolor{diagrambackground}{RGB}{252,252,252}');
    buffer.writeln();
    buffer.writeln('% ============================================================');
    buffer.writeln('% Code Listings Configuration');
    buffer.writeln('% ============================================================');
    buffer.writeln('\\lstset{');
    buffer.writeln('  backgroundcolor=\\color{codebackground},');
    buffer.writeln('  basicstyle=\\ttfamily\\small,');
    buffer.writeln('  breakatwhitespace=false,');
    buffer.writeln('  breaklines=true,');
    buffer.writeln('  captionpos=b,');
    buffer.writeln('  commentstyle=\\color{codecomment},');
    buffer.writeln('  frame=single,');
    buffer.writeln('  framerule=0.5pt,');
    buffer.writeln('  rulecolor=\\color{codeborder},');
    buffer.writeln('  keepspaces=true,');
    buffer.writeln('  keywordstyle=\\color{codekeyword}\\bfseries,');
    buffer.writeln('  numbers=left,');
    buffer.writeln('  numbersep=8pt,');
    buffer.writeln('  numberstyle=\\tiny\\color{gray},');
    buffer.writeln('  showspaces=false,');
    buffer.writeln('  showstringspaces=false,');
    buffer.writeln('  showtabs=false,');
    buffer.writeln('  stringstyle=\\color{codestring},');
    buffer.writeln('  tabsize=2,');
    buffer.writeln('  xleftmargin=12pt,');
    buffer.writeln('  xrightmargin=4pt,');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('% Language definitions');
    buffer.writeln('\\lstdefinelanguage{dart}{');
    buffer.writeln('  keywords={abstract,as,assert,async,await,break,case,catch,class,const,continue,covariant,default,deferred,do,dynamic,else,enum,export,extends,extension,external,factory,false,final,finally,for,Function,get,hide,if,implements,import,in,interface,is,late,library,mixin,new,null,on,operator,part,required,rethrow,return,set,show,static,super,switch,sync,this,throw,true,try,typedef,var,void,while,with,yield},');
    buffer.writeln('  sensitive=true,');
    buffer.writeln('  morecomment=[l]{//},');
    buffer.writeln('  morecomment=[s]{/*}{*/},');
    buffer.writeln("  morestring=[b]',");
    buffer.writeln('  morestring=[b]",');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('% ============================================================');
    buffer.writeln('% Custom Macros for Markdown Elements');
    buffer.writeln('% ============================================================');
    buffer.writeln();
    buffer.writeln('% Inline code');
    buffer.writeln('\\newcommand{\\mdinlinecode}[1]{%');
    buffer.writeln('  \\colorbox{codebackground}{\\texttt{#1}}%');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('% Block quote environment using framed');
    buffer.writeln('\\definecolor{shadecolor}{RGB}{245,245,245}');
    buffer.writeln('\\newenvironment{mdblockquote}{%');
    buffer.writeln('  \\def\\FrameCommand{\\vrule width 3pt\\colorbox{shadecolor}}%');
    buffer.writeln('  \\MakeFramed{\\advance\\hsize-\\width\\FrameRestore}%');
    buffer.writeln('}{\\endMakeFramed}');
    buffer.writeln();
    buffer.writeln('% ASCII diagram environment using framed');
    buffer.writeln('\\newenvironment{mdasciibox}{%');
    buffer.writeln('  \\begin{framed}%');
    buffer.writeln('}{\\end{framed}}');
    buffer.writeln();
    buffer.writeln('% Horizontal rule');
    buffer.writeln('\\newcommand{\\mdhorizontalrule}{%');
    buffer.writeln('  \\vspace{0.5em}');
    buffer.writeln('  \\noindent\\rule{\\textwidth}{0.4pt}');
    buffer.writeln('  \\vspace{0.5em}');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('% Hyperref configuration');
    buffer.writeln('\\hypersetup{');
    buffer.writeln('  colorlinks=true,');
    buffer.writeln('  linkcolor=linkcolor,');
    buffer.writeln('  filecolor=linkcolor,');
    buffer.writeln('  urlcolor=linkcolor,');
    buffer.writeln('  pdftitle={${title ?? "Document"}},');
    buffer.writeln('  pdfauthor={${author ?? ""}},');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('% Set TOC depth (1=section, 2=subsection, 3=subsubsection, etc.)');
    buffer.writeln('\\setcounter{tocdepth}{$tocDepth}');
    buffer.writeln('\\setcounter{secnumdepth}{$tocDepth}');
    buffer.writeln();
    buffer.writeln('% ============================================================');
    buffer.writeln('% Document Metadata');
    buffer.writeln('% ============================================================');
    if (title != null) {
      buffer.writeln('\\title{${escapeText(title)}}');
    }
    if (author != null) {
      buffer.writeln('\\author{${escapeText(author)}}');
    }
    buffer.writeln('\\date{${date ?? "\\\\today"}}');
    buffer.writeln();

    return buffer.toString();
  }

  /// Generates \\begin{document}.
  static String beginDocument() => '\\begin{document}\n';

  /// Generates \\end{document}.
  static String endDocument() => '\\end{document}\n';

  /// Generates \\maketitle.
  static String makeTitle() => '\\maketitle\n';

  /// Converts heading text to a URL-friendly slug for anchor labels.
  /// Matches GitHub/markdown-style anchor generation.
  static String textToSlug(String text) {
    // First unescape markdown escapes to match how markdown generates anchors
    var result = text
        .replaceAll(r'\&', '&')
        .replaceAll(r'\*', '*')
        .replaceAll(r'\_', '_')
        .replaceAll(r'\#', '#')
        .replaceAll(r'\[', '[')
        .replaceAll(r'\]', ']')
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\`', '`')
        .replaceAll(r'\\', '\\');
    
    return result
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // Remove special chars (including &)
        .replaceAll(' ', '-') // Replace EACH space with hyphen (preserves double spaces -> double hyphens)
        .replaceAll(RegExp(r'^-+|-+$'), ''); // Trim hyphens from ends only
  }

  /// Generates a section heading at the specified level.
  /// Adds both a numeric label and a slug-based label for cross-referencing.
  /// Set [numbered] to false to use starred versions (no section numbers).
  static String heading(String text, int level, {String? label, bool numbered = true}) {
    // Unescape markdown-escaped angle brackets first
    var processedText = text.replaceAll(r'\<', '<').replaceAll(r'\>', '>');
    final escaped = escapeText(processedText);
    
    // Generate both numeric and slug labels for maximum compatibility
    final numericLabel = label != null ? '\\label{$label}' : '';
    final slugLabel = '\\label{${textToSlug(text)}}';
    final labels = '$numericLabel$slugLabel';
    
    // Use starred versions for unnumbered headings
    final star = numbered ? '' : '*';
    
    switch (level) {
      case 1:
        return '\\section$star{$escaped}$labels';
      case 2:
        return '\\subsection$star{$escaped}$labels';
      case 3:
        return '\\subsubsection$star{$escaped}$labels';
      case 4:
        // \paragraph is run-in by default, add line break and spacing after
        return '\\paragraph$star{$escaped}$labels\\mbox{}\\\\[1ex]';
      case 5:
        // \subparagraph is run-in by default, add line break and spacing after
        return '\\subparagraph$star{$escaped}$labels\\mbox{}\\\\[1ex]';
      default:
        return '\\textbf{$escaped}';
    }
  }

  /// Generates a paragraph.
  static String paragraph(String text) => '$text\n';

  /// Generates bold text.
  static String bold(String text) => '\\textbf{$text}';

  /// Generates italic text.
  static String italic(String text) => '\\textit{$text}';

  /// Generates inline code.
  static String inlineCode(String code) {
    // Use texttt with escaped special characters
    // \verb cannot span lines and causes issues when output is wrapped
    final escaped = _escapeTextTT(code);
    return '\\texttt{$escaped}';
  }
  
  static String _escapeTextTT(String code) {
    // Escape special LaTeX characters for use in \texttt
    return code
        .replaceAll(r'\', r'\textbackslash{}')
        .replaceAll('{', r'\{')
        .replaceAll('}', r'\}')
        .replaceAll('%', r'\%')
        .replaceAll('&', r'\&')
        .replaceAll('#', r'\#')
        .replaceAll('_', r'\_')
        .replaceAll('^', r'\^{}')
        .replaceAll('~', r'\textasciitilde{}')
        .replaceAll(r'$', r'\$');
  }

  /// Generates a code block with optional language highlighting.
  static String codeBlock(String code, {String? language}) {
    final buffer = StringBuffer();
    final lang = _mapLanguage(language);

    buffer.writeln('\\begin{lstlisting}${lang != null ? "[language=$lang]" : ""}');
    buffer.writeln(code);
    buffer.writeln('\\end{lstlisting}');

    return buffer.toString();
  }

  static String? _mapLanguage(String? language) {
    if (language == null || language.isEmpty) return null;
    final lang = language.toLowerCase();
    const mapping = {
      'dart': 'dart',
      'java': 'Java',
      'javascript': 'JavaScript',
      'js': 'JavaScript',
      'typescript': 'JavaScript',
      'ts': 'JavaScript',
      'python': 'Python',
      'py': 'Python',
      'c': 'C',
      'cpp': 'C++',
      'c++': 'C++',
      'csharp': 'C',
      'cs': 'C',
      'go': 'Go',
      'rust': 'Rust',
      'ruby': 'Ruby',
      'php': 'PHP',
      'sql': 'SQL',
      'bash': 'bash',
      'sh': 'bash',
      'shell': 'bash',
      'yaml': 'yaml',
      'yml': 'yaml',
      'json': 'json',
      'xml': 'XML',
      'html': 'HTML',
      'css': 'CSS',
    };
    return mapping[lang];
  }

  /// Generates an ASCII diagram block (preserved formatting).
  static String asciiDiagram(String diagram) {
    final buffer = StringBuffer();
    // Use simple verbatim without nesting in framed to avoid memory issues
    buffer.writeln('\\begin{verbatim}');
    // Convert box-drawing Unicode to ASCII equivalents
    var converted = diagram
        .replaceAll('├', '|--')
        .replaceAll('└', '\\--')
        .replaceAll('│', '|')
        .replaceAll('─', '-')
        .replaceAll('┬', '-+-')
        .replaceAll('┴', '-+-')
        .replaceAll('┼', '-+-')
        .replaceAll('┤', '--|')
        .replaceAll('┌', '.--')
        .replaceAll('┐', '--.')
        .replaceAll('┘', "--'")
        .replaceAll('┐', '--.');
    buffer.writeln(converted);
    buffer.writeln('\\end{verbatim}');
    return buffer.toString();
  }

  /// Generates a table with full-width columns and borders.
  static String table(
    List<String> headers,
    List<List<String>> rows,
    List<String> alignments,
  ) {
    final buffer = StringBuffer();
    final numCols = headers.length;

    // Use tabularx with X columns to span full page width
    // With | for vertical borders
    final colSpec = List.generate(numCols, (i) => 'X').join('|');

    // Use samepage to keep table together, allowing break before it
    buffer.writeln('\\begin{samepage}');

    // Increase row height for better readability (1.4 = 40% more space)
    buffer.writeln('{\\renewcommand{\\arraystretch}{1.4}');

    // Using tabularx with ltablex for page breaks
    buffer.writeln('\\begin{tabularx}{\\textwidth}{|$colSpec|}');
    buffer.writeln('\\hline');

    // Header row with bold text
    final escapedHeaders = headers.map((h) => '\\textbf{${escapeText(h)}}').toList();
    buffer.writeln('${escapedHeaders.join(' & ')} \\\\');
    buffer.writeln('\\hline');

    // Data rows with horizontal lines between each
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final escapedRow = row.map((cell) => _escapeTableCell(cell)).toList();
      // Pad row if needed
      while (escapedRow.length < numCols) {
        escapedRow.add('');
      }
      buffer.writeln('${escapedRow.take(numCols).join(' & ')} \\\\');
      buffer.writeln('\\hline');
    }

    buffer.writeln('\\end{tabularx}');
    buffer.writeln('}'); // Close \renewcommand scope
    buffer.writeln('\\end{samepage}');

    return buffer.toString();
  }

  /// Escape table cell content, handling inline code specially.
  static String _escapeTableCell(String cell) {
    // Unescape markdown angle brackets first
    var processed = cell.replaceAll(r'\<', '<').replaceAll(r'\>', '>');
    
    // Check if cell contains backticks (inline code)
    if (processed.contains('`')) {
      // Extract code and format it
      processed = processed.replaceAllMapped(
        RegExp(r'`([^`]+)`'),
        (m) {
          final code = m.group(1) ?? '';
          return '\\texttt{${_escapeWithBreaks(code)}}';
        },
      );
      // Escape remaining text but preserve the \texttt blocks
      return processed;
    }
    return _escapeWithBreaks(processed);
  }

  /// Escape text and add line break opportunities before brackets.
  static String _escapeWithBreaks(String text) {
    var result = escapeText(text);
    // Add \allowbreak before opening brackets for line break opportunities
    result = result.replaceAll('<', '\\allowbreak<');
    result = result.replaceAll('(', '\\allowbreak(');
    result = result.replaceAll('[', '\\allowbreak[');
    return result;
  }

  /// Generates an unordered list.
  static String unorderedList(List<String> items) {
    final buffer = StringBuffer();
    buffer.writeln('\\begin{itemize}[leftmargin=*]');
    for (final item in items) {
      buffer.writeln('  \\item $item');
    }
    buffer.writeln('\\end{itemize}');
    return buffer.toString();
  }

  /// Generates an ordered list.
  static String orderedList(List<String> items) {
    final buffer = StringBuffer();
    buffer.writeln('\\begin{enumerate}[leftmargin=*]');
    for (final item in items) {
      buffer.writeln('  \\item $item');
    }
    buffer.writeln('\\end{enumerate}');
    return buffer.toString();
  }

  /// Generates a block quote.
  static String blockQuote(String text) {
    final buffer = StringBuffer();
    buffer.writeln('\\begin{mdblockquote}');
    buffer.writeln(text);
    buffer.writeln('\\end{mdblockquote}');
    return buffer.toString();
  }

  /// Generates a horizontal rule.
  static String horizontalRule() => '\\mdhorizontalrule\n';

  /// Generates a hyperlink.
  /// Internal links (starting with #) use \hyperref, external use \href.
  static String link(String text, String url) {
    final escapedText = escapeText(text);
    
    // Handle internal anchor links
    if (url.startsWith('#')) {
      final anchor = url.substring(1); // Remove the # prefix
      return '\\hyperref[$anchor]{$escapedText}';
    }
    
    // External links use href
    return '\\href{$url}{$escapedText}';
  }

  /// Generates an image.
  static String image(String altText, String url) {
    final buffer = StringBuffer();
    buffer.writeln('\\begin{figure}[htbp]');
    buffer.writeln('  \\centering');
    buffer.writeln('  \\includegraphics[max width=\\textwidth]{$url}');
    if (altText.isNotEmpty) {
      buffer.writeln('  \\caption{${escapeText(altText)}}');
    }
    buffer.writeln('\\end{figure}');
    return buffer.toString();
  }

  /// Escapes LaTeX special characters in text.
  static String escapeText(String text) {
    var result = text;

    // First, unescape markdown escape sequences (e.g., \& -> &, \* -> *)
    // These are common in markdown to escape special characters
    result = result.replaceAll(r'\&', '&');
    result = result.replaceAll(r'\*', '*');
    result = result.replaceAll(r'\_', '_');
    result = result.replaceAll(r'\#', '#');
    result = result.replaceAll(r'\[', '[');
    result = result.replaceAll(r'\]', ']');
    result = result.replaceAll(r'\(', '(');
    result = result.replaceAll(r'\)', ')');
    result = result.replaceAll(r'\`', '`');
    result = result.replaceAll(r'\\', '\x00BACKSLASH\x00'); // Preserve actual backslashes temporarily

    // Now escape LaTeX special characters
    result = result.replaceAll('&', '\\&');
    result = result.replaceAll('%', '\\%');
    result = result.replaceAll('\$', '\\\$');
    result = result.replaceAll('#', '\\#');
    result = result.replaceAll('_', '\\_');
    result = result.replaceAll('{', '\\{');
    result = result.replaceAll('}', '\\}');
    result = result.replaceAll('^', '\\^{}');
    result = result.replaceAll('~', '\\~{}');
    
    // Restore actual backslashes
    result = result.replaceAll('\x00BACKSLASH\x00', '\\textbackslash{}');

    return result;
  }
}
