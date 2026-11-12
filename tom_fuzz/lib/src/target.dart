import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Whether [error] is the parser's declared way of rejecting an input.
typedef RejectionTest = bool Function(Object error);

/// A parser under test.
///
/// [run] is given each input. It returns normally when it accepts the input
/// and throws when it rejects it; [rejects] says which errors are the
/// declared rejection (`FormatException`, the parser's own exception type).
/// Every other error is a finding, as is a run that does not finish within the
/// fuzzer's time bound or that grows memory past its bound.
///
/// The target runs in a worker isolate, so [run] and [rejects] must be
/// sendable to one: top-level or static functions, or closures over
/// sendable state.
class FuzzTarget {
  /// The target's name: it names its corpus folder, its failures and its
  /// report.
  final String name;

  /// Parses one input.
  final FutureOr<void> Function(Uint8List input) run;

  /// Whether an error is the declared rejection.
  final RejectionTest rejects;

  /// A target taking the raw bytes.
  const FuzzTarget(this.name, this.run, {required this.rejects});

  /// A target taking the input as text: the bytes decoded as UTF-8, a
  /// malformed sequence replaced by U+FFFD, so the parser sees every string a
  /// caller could hand it.
  factory FuzzTarget.text(
    String name,
    FutureOr<void> Function(String input) run, {
    required RejectionTest rejects,
  }) => FuzzTarget(
    name,
    (bytes) => run(utf8.decode(bytes, allowMalformed: true)),
    rejects: rejects,
  );
}

/// A [RejectionTest] accepting the error types [T1] (and [T2], [T3]).
///
/// ```dart
/// rejects: rejectsAny<FormatException, ParseError, Never>
/// ```
bool rejectsAny<T1, T2, T3>(Object error) =>
    error is T1 || error is T2 || error is T3;

/// Rejects with a `FormatException` only — what most decoders throw.
bool rejectsFormatException(Object error) => error is FormatException;
