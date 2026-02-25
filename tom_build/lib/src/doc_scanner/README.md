# DocScanner

A tool for parsing markdown files into structured JSON data.

DocScanner processes markdown files and extracts headline-based structure into a traversable tree of sections. This enables scripted processing of markdown documentation.

## Features

- **Parse Headlines**: Extracts all headline levels (`#` through `######`)
- **Extract IDs**: Supports explicit IDs via `[id]` or `<!--[id]-->` syntax
- **Auto-generate IDs**: Creates IDs from headline text when not specified
- **Section Hierarchy**: Builds nested section tree based on headline levels
- **Path Information**: Tracks file paths relative to workspace and project roots
- **JSON Output**: Full serialization support for all data structures

## Installation

DocScanner is part of the `tom_build` package:

```yaml
dependencies:
  tom_build:
    path: ../tom_build
```

## Usage

### Library API

```dart
import 'package:tom_build/doc_scanner.dart';

// Scan a single document
final doc = await DocScanner.scanDocument(filepath: 'README.md');
print('Document: ${doc.name}');
print('Sections: ${doc.sections?.length ?? 0}');

// Scan multiple documents
final docs = await DocScanner.scanDocuments(
  filepaths: ['doc1.md', 'doc2.md'],
);

// Scan a directory tree
final folder = await DocScanner.scanTree(path: 'doc/');
print('Total documents: ${folder.allDocuments.length}');
```

### Command-Line Tool

```bash
# Scan a single file
dart run tom_build_tools:doc_scanner scandocument README.md

# Scan multiple files
dart run tom_build_tools:doc_scanner scandocuments doc1.md doc2.md -target=output

# Scan a directory tree
dart run tom_build_tools:doc_scanner scantree doc/ -target=json-output

# Flatten output (all files in one directory)
dart run tom_build_tools:doc_scanner scantree doc/ -flat -target=all-json
```

## Data Model

### Section

Represents a headline and its content:

```dart
class Section {
  final int index;        // Position among siblings
  final int lineNumber;   // Source line number (1-based)
  final String name;      // Headline text
  final String id;        // Unique identifier
  final String text;      // Content between headlines
  final List<Section>? sections;  // Nested subsections
}
```

### Document

Extends Section with file path information:

```dart
class Document extends Section {
  final String filenameWithPath;  // Full file path
  final String loadTimestamp;     // ISO timestamp
  final String filename;          // Base filename
  final String fullPath;          // Directory path
  final String workspacePath;     // Workspace-relative path
  final String project;           // Project name
  final String projectPath;       // Project-relative path
  final String workspaceRoot;     // Workspace root path
  final String projectRoot;       // Project root path
  final int hierarchyDepth;       // Maximum headline depth
}
```

### DocumentFolder

Represents a directory of documents:

```dart
class DocumentFolder {
  final String foldername;
  final String workspaceFolderPath;
  final String absoluteFolderPath;
  final List<Document> documents;
  final List<DocumentFolder> folders;

  List<Document> get allDocuments; // Flattened list
}
```

## ID Extraction

DocScanner supports two formats for explicit IDs:

### Square Brackets

```markdown
## [my-section] Section Title
```

### HTML Comments

```markdown
## <!--[my-section]--> Section Title
```

HTML comments are useful when you want IDs that don't render in the markdown preview.

### Auto-generated IDs

If no explicit ID is provided:

1. **Single word**: Lowercased (e.g., `Introduction` → `introduction`)
2. **Multiple words**: Uses `parent.index` pattern (e.g., `intro.0`, `intro.1`)

## JSON Output Format

```json
{
  "index": 0,
  "lineNumber": 1,
  "name": "Document Title",
  "id": "document_title",
  "text": "Introductory text...",
  "sections": [
    {
      "index": 0,
      "lineNumber": 5,
      "name": "First Section",
      "id": "first_section",
      "text": "Section content...",
      "sections": null
    }
  ],
  "filenameWithPath": "/path/to/document.md",
  "loadTimestamp": "2026-01-14T10:00:00.000Z",
  "filename": "document.md",
  "fullPath": "/path/to",
  "workspacePath": "project/document.md",
  "project": "project",
  "projectPath": "document.md",
  "workspaceRoot": "/workspace",
  "projectRoot": "/workspace/project",
  "hierarchyDepth": 2
}
```

## See Also

- [tom_build](../README.md) - Parent package documentation
- [Markdown Specification](https://commonmark.org/) - CommonMark standard
