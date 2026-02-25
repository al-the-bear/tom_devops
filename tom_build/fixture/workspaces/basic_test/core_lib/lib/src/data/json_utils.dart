/// JSON utility functions
library;

/// Converts a map to JSON-safe format
Map<String, dynamic> toJsonSafe(Map<String, dynamic> input) {
  return Map.from(input);
}
