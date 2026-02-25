/// Serialization utilities
library;

/// Base interface for serializable objects
abstract class Serializable {
  Map<String, dynamic> toJson();
}
