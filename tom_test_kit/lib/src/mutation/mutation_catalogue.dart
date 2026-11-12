import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The default catalogue of a package, relative to its root.
const kDefaultMutationCatalogue = 'tool/mutations.yaml';

/// The default precondition declarations of a package, relative to its root.
const kDefaultMutationRequirements = 'tool/mutation_requirements.yaml';

/// A catalogue or requirements file that cannot be used as written.
class MutationConfigError implements Exception {
  /// What is wrong.
  final String message;

  /// Creates the error.
  MutationConfigError(this.message);

  @override
  String toString() => message;
}

/// One catalogued mutation: the smallest edit that removes one promise, and
/// the tests expected to notice.
class MutationEntry {
  /// The module (top-level key) it belongs to.
  final String module;

  /// The behaviour the edit removes.
  final String behaviour;

  /// The file, relative to the package root.
  final String file;

  /// The text replaced; must occur in [file] exactly once.
  final String find;

  /// What it is replaced with.
  final String replace;

  /// The test files that must fail.
  final List<String> tests;

  /// Preconditions (declared in the requirements file) without which the
  /// tests would self-skip.
  final List<String> requires;

  /// Creates an entry.
  const MutationEntry({
    required this.module,
    required this.behaviour,
    required this.file,
    required this.find,
    required this.replace,
    required this.tests,
    this.requires = const [],
  });

  /// The entry as JSON.
  Map<String, Object?> toJson() => {
    'module': module,
    'behaviour': behaviour,
    'file': file,
    'find': find,
    'replace': replace,
    'tests': tests,
    if (requires.isNotEmpty) 'requires': requires,
  };
}

/// A package's mutation catalogue: module -> entries, in file order.
///
/// ```yaml
/// cache:
///   - behaviour: a read promotes the entry to most-recently-used
///     file: lib/src/cache/server_cache.dart
///     find: "        if (_first != entry) {"
///     replace: "        if (false) {"
///     tests: test/cache_test.dart test/cache_lru_test.dart
///     requires: db
/// ```
///
/// `tests` and `requires` are space-separated. The file is read line by line
/// (see [MutationCatalogue.parse]), not as YAML.
class MutationCatalogue {
  /// Modules in file order.
  final Map<String, List<MutationEntry>> modules;

  /// Creates a catalogue.
  const MutationCatalogue(this.modules);

  /// Reads [path].
  factory MutationCatalogue.load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw MutationConfigError('no mutation catalogue at $path');
    }
    return MutationCatalogue.parse(file.readAsStringSync(), source: path);
  }

  /// Reads a catalogue from [text].
  ///
  /// The grammar is line-based, as the tom_core_server script that the
  /// catalogues come from reads it, and not YAML: an unquoted value may hold
  /// `: ` (`behaviour: a read: then a write`), which YAML refuses. An
  /// unindented `name:` line starts a module; `- ` starts an entry; every
  /// other line is `key: value`, split at the first `: `; a value in double
  /// quotes has its escapes decoded (`\n`, `\t`, `\"`, `\\`, `\uXXXX`, ...).
  /// Blank lines and `#` comment lines are skipped.
  factory MutationCatalogue.parse(String text, {String source = 'catalogue'}) {
    final raw = <String, List<Map<String, String>>>{};
    String? module;
    Map<String, String>? entry;
    for (final (index, rawLine) in text.split('\n').indexed) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      if (!line.startsWith(' ') && line.endsWith(':')) {
        module = line.substring(0, line.length - 1);
        raw[module] = [];
        entry = null;
        continue;
      }
      if (module == null) {
        throw MutationConfigError(
          '$source:${index + 1}: an entry before any module',
        );
      }
      var stripped = line.trim();
      if (stripped.startsWith('- ')) {
        entry = {};
        raw[module]!.add(entry);
        stripped = stripped.substring(2);
      }
      if (entry == null) {
        throw MutationConfigError(
          '$source:${index + 1}: a key outside an entry (`- ` missing)',
        );
      }
      final colon = stripped.indexOf(': ');
      final key = colon < 0
          ? (stripped.endsWith(':')
                ? stripped.substring(0, stripped.length - 1)
                : stripped)
          : stripped.substring(0, colon);
      var value = colon < 0 ? '' : stripped.substring(colon + 2).trim();
      if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
        value = _unescape(value.substring(1, value.length - 1));
      }
      entry[key] = value;
    }
    if (raw.isEmpty) {
      throw MutationConfigError('$source: no module');
    }
    return MutationCatalogue({
      for (final MapEntry(key: name, value: entries) in raw.entries)
        name: [
          for (final (i, e) in entries.indexed) _entry(source, name, i, e),
        ],
    });
  }

  static String _unescape(String s) {
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c != '\\' || i + 1 >= s.length) {
        b.write(c);
        continue;
      }
      final n = s[++i];
      switch (n) {
        case 'n':
          b.write('\n');
        case 't':
          b.write('\t');
        case 'r':
          b.write('\r');
        case '0':
          b.write('\u0000');
        case '\\' || '"' || "'":
          b.write(n);
        case 'x' || 'u' || 'U':
          final len = n == 'x' ? 2 : (n == 'u' ? 4 : 8);
          final code = i + len < s.length + 1
              ? int.tryParse(s.substring(i + 1, i + 1 + len), radix: 16)
              : null;
          if (code == null) {
            b.write('\\$n');
          } else {
            b.writeCharCode(code);
            i += len;
          }
        default:
          b.write('\\$n');
      }
    }
    return b.toString();
  }

  static MutationEntry _entry(
    String source,
    String module,
    int i,
    Map<String, String> raw,
  ) {
    String where() => '$source: $module #${i + 1}';
    String text(String key, {bool required = true}) {
      final value = raw[key];
      if (value == null) {
        if (required) throw MutationConfigError('${where()} has no `$key:`');
        return '';
      }
      return value;
    }

    List<String> words(String key) => (raw[key] ?? '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final tests = words('tests');
    if (tests.isEmpty) throw MutationConfigError('${where()} names no tests');
    if (text('find').isEmpty) {
      throw MutationConfigError('${where()} has an empty `find:`');
    }
    return MutationEntry(
      module: module,
      behaviour: text('behaviour'),
      file: text('file'),
      find: text('find'),
      replace: text('replace', required: false),
      tests: tests,
      requires: words('requires'),
    );
  }

  /// Every entry, module by module.
  Iterable<MutationEntry> get entries => modules.values.expand((e) => e);
}

/// A precondition a package declares: something the named tests need, without
/// which they self-skip and every mutation they cover would look like a
/// survivor.
///
/// ```yaml
/// db:
///   description: MariaDB of the db-tagged suites
///   tcp: 127.0.0.1:3309          # or env: NAME, file: path, command: shell line
/// ```
class MutationRequirement {
  /// The name entries use in `requires:`.
  final String name;

  /// What it is, for messages.
  final String description;

  /// `host:port` that must accept a connection.
  final String? tcp;

  /// An environment variable that must be set and non-empty.
  final String? env;

  /// A path (relative to the package) that must exist.
  final String? file;

  /// A shell command that must exit 0 within 10 seconds.
  final String? command;

  /// Creates a requirement.
  const MutationRequirement({
    required this.name,
    this.description = '',
    this.tcp,
    this.env,
    this.file,
    this.command,
  });

  /// Null when the precondition holds in [packageRoot], else why not.
  Future<String?> unmet(String packageRoot) async {
    if (tcp != null) {
      final colon = tcp!.lastIndexOf(':');
      final host = tcp!.substring(0, colon);
      final port = int.parse(tcp!.substring(colon + 1));
      try {
        final socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 1),
        );
        socket.destroy();
      } on SocketException {
        return 'nothing listens on $tcp';
      }
    }
    if (env != null && (Platform.environment[env!] ?? '').isEmpty) {
      return '\$$env is not set';
    }
    if (file != null &&
        FileSystemEntity.typeSync(p.join(packageRoot, file!)) ==
            FileSystemEntityType.notFound) {
      return '$file does not exist';
    }
    if (command != null) {
      final ProcessResult result;
      try {
        result = await Process.run(Platform.isWindows ? 'cmd' : 'sh', [
          Platform.isWindows ? '/c' : '-c',
          command!,
        ], workingDirectory: packageRoot).timeout(const Duration(seconds: 10));
      } on Exception {
        return '`$command` did not finish';
      }
      if (result.exitCode != 0) {
        return '`$command` exited ${result.exitCode}';
      }
    }
    return null;
  }

  /// Reads the declarations in [path]; none when the file does not exist.
  static Map<String, MutationRequirement> load(String path) {
    final file = File(path);
    if (!file.existsSync()) return const {};
    final Object? yaml;
    try {
      yaml = loadYaml(file.readAsStringSync());
    } on YamlException catch (e) {
      throw MutationConfigError('$path does not parse: ${e.message}');
    }
    if (yaml == null) return const {};
    if (yaml is! Map) {
      throw MutationConfigError('$path: expected requirement name -> checks');
    }
    final result = <String, MutationRequirement>{};
    for (final MapEntry(:key, :value) in yaml.entries) {
      final name = '$key';
      if (value is! Map) {
        throw MutationConfigError('$path: `$name` is not a map');
      }
      String? opt(String k) => value[k] == null ? null : '${value[k]}';
      final requirement = MutationRequirement(
        name: name,
        description: opt('description') ?? '',
        tcp: opt('tcp'),
        env: opt('env'),
        file: opt('file'),
        command: opt('command'),
      );
      if ([
        requirement.tcp,
        requirement.env,
        requirement.file,
        requirement.command,
      ].every((c) => c == null)) {
        throw MutationConfigError(
          '$path: `$name` declares no check (tcp, env, file or command)',
        );
      }
      final tcp = requirement.tcp;
      if (tcp != null && !RegExp(r'^.+:\d+$').hasMatch(tcp)) {
        throw MutationConfigError('$path: `$name`: tcp must be host:port');
      }
      result[name] = requirement;
    }
    return result;
  }
}
