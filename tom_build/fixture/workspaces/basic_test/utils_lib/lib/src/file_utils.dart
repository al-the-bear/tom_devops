/// File utility functions
library;

import 'dart:io';

/// Reads a file and returns its content
String readFileContent(String path) {
  return File(path).readAsStringSync();
}

/// Checks if a file exists
bool fileExists(String path) {
  return File(path).existsSync();
}
