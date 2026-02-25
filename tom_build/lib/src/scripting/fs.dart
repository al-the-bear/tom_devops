/// Filesystem utilities for scripting.
///
/// Provides convenient static methods for common filesystem operations
/// like reading, writing, copying, and deleting files.
library;

import 'dart:io';

/// Filesystem operations helper.
///
/// All methods are static for convenient use in D4rt scripts.
///
/// ## Example
/// ```dart
/// // Read a file
/// final content = Fs.read('config.yaml');
///
/// // Write to a file
/// Fs.write('output.txt', 'Hello World');
///
/// // Check if file exists
/// if (Fs.exists('data.json')) { ... }
///
/// // List directory
/// final files = TomFs.ls('src/', recursive: true);
/// ```
class TomFs {
  TomFs._(); // Prevent instantiation

  // =========================================================================
  // Read Operations
  // =========================================================================

  /// Read file contents as string.
  ///
  /// [path] - Path to the file
  /// Throws [FileSystemException] if file doesn't exist
  static String read(String path) {
    return File(path).readAsStringSync();
  }

  /// Read file contents as bytes.
  static List<int> readBytes(String path) {
    return File(path).readAsBytesSync();
  }

  /// Read file as lines.
  static List<String> readLines(String path) {
    return File(path).readAsLinesSync();
  }

  /// Read file, return null if doesn't exist.
  static String? tryRead(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  // =========================================================================
  // Write Operations
  // =========================================================================

  /// Write string content to file.
  ///
  /// Creates parent directories if they don't exist.
  ///
  /// [path] - Path to the file
  /// [content] - Content to write
  static void write(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  /// Write bytes to file.
  static void writeBytes(String path, List<int> bytes) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
  }

  /// Append string content to file.
  static void append(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content, mode: FileMode.append);
  }

  /// Append a line to file (adds newline).
  static void appendLine(String path, String line) {
    append(path, '$line\n');
  }

  // =========================================================================
  // File/Directory Checks
  // =========================================================================

  /// Check if path exists (file or directory).
  static bool exists(String path) {
    return File(path).existsSync() || Directory(path).existsSync();
  }

  /// Check if path is a file.
  static bool isFile(String path) {
    return File(path).existsSync();
  }

  /// Check if path is a directory.
  static bool isDir(String path) {
    return Directory(path).existsSync();
  }

  /// Check if file is empty.
  static bool isEmpty(String path) {
    final file = File(path);
    if (!file.existsSync()) return true;
    return file.lengthSync() == 0;
  }

  // =========================================================================
  // File Operations
  // =========================================================================

  /// Copy a file or directory.
  ///
  /// [from] - Source path
  /// [to] - Destination path
  /// [overwrite] - If true, overwrite existing files
  static void copy(String from, String to, {bool overwrite = true}) {
    if (isDir(from)) {
      _copyDir(Directory(from), Directory(to), overwrite: overwrite);
    } else {
      final destFile = File(to);
      if (destFile.existsSync() && !overwrite) {
        throw FileSystemException('File already exists', to);
      }
      destFile.parent.createSync(recursive: true);
      File(from).copySync(to);
    }
  }

  /// Move/rename a file or directory.
  static void move(String from, String to) {
    if (isDir(from)) {
      Directory(from).renameSync(to);
    } else {
      File(from).renameSync(to);
    }
  }

  /// Delete a file or directory.
  ///
  /// [path] - Path to delete
  /// [recursive] - If true, delete directory contents recursively
  static void delete(String path, {bool recursive = false}) {
    if (isDir(path)) {
      Directory(path).deleteSync(recursive: recursive);
    } else if (isFile(path)) {
      File(path).deleteSync();
    }
  }

  /// Delete if exists, don't throw if missing.
  static void deleteIfExists(String path, {bool recursive = false}) {
    if (exists(path)) {
      delete(path, recursive: recursive);
    }
  }

  // =========================================================================
  // Directory Operations
  // =========================================================================

  /// Create a directory (and parent directories).
  static void mkdir(String path) {
    Directory(path).createSync(recursive: true);
  }

  /// List directory contents.
  ///
  /// [path] - Directory path
  /// [recursive] - If true, list recursively
  /// [filesOnly] - If true, only return files
  /// [dirsOnly] - If true, only return directories
  static List<String> ls(
    String path, {
    bool recursive = false,
    bool filesOnly = false,
    bool dirsOnly = false,
  }) {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];

    final entities = dir.listSync(recursive: recursive);
    final results = <String>[];

    for (final entity in entities) {
      if (filesOnly && entity is! File) continue;
      if (dirsOnly && entity is! Directory) continue;
      results.add(entity.path);
    }

    return results;
  }

  /// List only files in directory.
  static List<String> files(String path, {bool recursive = false}) {
    return ls(path, recursive: recursive, filesOnly: true);
  }

  /// List only subdirectories.
  static List<String> dirs(String path, {bool recursive = false}) {
    return ls(path, recursive: recursive, dirsOnly: true);
  }

  // =========================================================================
  // File Info
  // =========================================================================

  /// Get file size in bytes.
  static int size(String path) {
    return File(path).lengthSync();
  }

  /// Get file modification time.
  static DateTime mtime(String path) {
    return File(path).lastModifiedSync();
  }

  /// Get file access time.
  static DateTime atime(String path) {
    return File(path).lastAccessedSync();
  }

  /// Set file modification time.
  static void touch(String path, [DateTime? time]) {
    final file = File(path);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.setLastModifiedSync(time ?? DateTime.now());
  }

  // =========================================================================
  // Helper Methods
  // =========================================================================

  /// Copy directory recursively.
  static void _copyDir(Directory from, Directory to, {bool overwrite = true}) {
    to.createSync(recursive: true);
    for (final entity in from.listSync()) {
      final destPath = '${to.path}/${entity.uri.pathSegments.last}';
      if (entity is File) {
        entity.copySync(destPath);
      } else if (entity is Directory) {
        _copyDir(entity, Directory(destPath), overwrite: overwrite);
      }
    }
  }

  // =========================================================================
  // Temporary Files and Directories
  // =========================================================================

  /// Creates a temporary file and returns its path.
  ///
  /// [prefix] - Optional prefix for the file name
  /// [suffix] - Optional suffix (extension) for the file name
  /// [content] - Optional initial content to write
  ///
  /// The file is created in the system temp directory.
  /// Remember to delete it when done.
  static String temp({String? prefix, String? suffix, String? content}) {
    final dir = Directory.systemTemp;
    final name =
        '${prefix ?? 'tmp'}_${DateTime.now().millisecondsSinceEpoch}${suffix ?? ''}';
    final file = File('${dir.path}/$name');
    if (content != null) {
      file.writeAsStringSync(content);
    } else {
      file.createSync();
    }
    return file.path;
  }

  /// Creates a temporary directory and returns its path.
  ///
  /// [prefix] - Optional prefix for the directory name
  ///
  /// The directory is created in the system temp directory.
  /// Remember to delete it when done.
  static String tempDir({String? prefix}) {
    final name = '${prefix ?? 'tmp'}_${DateTime.now().millisecondsSinceEpoch}';
    final dir = Directory('${Directory.systemTemp.path}/$name');
    dir.createSync();
    return dir.path;
  }
}
