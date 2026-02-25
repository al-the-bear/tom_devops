/// Tool Context - Shared workspace context for all tom_build_cli.
///
/// Provides a central place to load and access workspace metadata from
/// `.tom_metadata/tom_master.yaml`. This ensures all tools operate on the same
/// workspace information.
library;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'workspace_info.dart';

export 'workspace_info.dart';

/// The CPU architecture of the current system.
///
/// Possible values:
/// - `x64` - 64-bit x86 architecture (also known as amd64, x86_64)
/// - `arm64` - 64-bit ARM architecture (also known as aarch64)
/// - `arm` - 32-bit ARM architecture
/// - `ia32` - 32-bit x86 architecture
/// - `riscv64` - 64-bit RISC-V architecture
/// - `unknown` - Unknown or unsupported architecture
enum CpuArchitecture {
  /// 64-bit x86 architecture (also known as amd64, x86_64).
  x64,

  /// 64-bit ARM architecture (also known as aarch64).
  arm64,

  /// 32-bit ARM architecture.
  arm,

  /// 32-bit x86 architecture.
  ia32,

  /// 64-bit RISC-V architecture.
  riscv64,

  /// Unknown or unsupported architecture.
  unknown;

  @override
  String toString() => name;
}

/// The operating system of the current system.
///
/// Possible values: `macos`, `linux`, `windows`, `fuchsia`, `unknown`.
enum OperatingSystem {
  macos,
  linux,
  windows,
  fuchsia,
  unknown;

  @override
  String toString() => name;
}

/// Platform information combining OS and architecture.
///
/// Uses VS Code extension platform naming convention.
class PlatformInfo {
  /// The operating system.
  final OperatingSystem os;

  /// The CPU architecture.
  final CpuArchitecture architecture;

  /// The platform identifier (e.g., 'darwin-arm64', 'linux-x64', 'win32-x64').
  ///
  /// Uses VS Code extension platform naming convention.
  final String platform;

  /// List of Dart target platforms that can be built on this platform.
  ///
  /// Dart cannot cross-compile to different OS, but can compile to different
  /// architectures on the same OS in some cases (e.g., x64 on arm64 macOS).
  final List<String> dartTargetPlatforms;

  const PlatformInfo._internal({
    required this.os,
    required this.architecture,
    required this.platform,
    required this.dartTargetPlatforms,
  });

  /// Detects the current platform from the Dart runtime.
  factory PlatformInfo.detect() {
    final os = _detectOs();
    final architecture = _detectArchitecture();
    final platform = _buildPlatformString(os, architecture);
    final dartTargetPlatforms = _getDartTargetPlatforms(os, architecture);

    return PlatformInfo._internal(
      os: os,
      architecture: architecture,
      platform: platform,
      dartTargetPlatforms: dartTargetPlatforms,
    );
  }

  /// Detects the operating system from Platform.operatingSystem.
  static OperatingSystem _detectOs() {
    switch (Platform.operatingSystem) {
      case 'macos':
        return OperatingSystem.macos;
      case 'linux':
        return OperatingSystem.linux;
      case 'windows':
        return OperatingSystem.windows;
      case 'fuchsia':
        return OperatingSystem.fuchsia;
      default:
        return OperatingSystem.unknown;
    }
  }

  /// Detects the CPU architecture from Platform.version.
  ///
  /// Platform.version contains the architecture suffix, e.g.:
  /// "3.2.0 (stable) on \"macos_arm64\""
  static CpuArchitecture _detectArchitecture() {
    final version = Platform.version.toLowerCase();
    if (version.contains('arm64') || version.contains('aarch64')) {
      return CpuArchitecture.arm64;
    } else if (version.contains('riscv64')) {
      return CpuArchitecture.riscv64;
    } else if (version.contains('x64') || version.contains('x86_64') || version.contains('amd64')) {
      return CpuArchitecture.x64;
    } else if (version.contains('ia32') || version.contains('x86')) {
      return CpuArchitecture.ia32;
    } else if (version.contains('arm')) {
      // Check arm after arm64 to avoid false match
      return CpuArchitecture.arm;
    }
    return CpuArchitecture.unknown;
  }

  /// Builds the platform string using VS Code extension naming convention.
  static String _buildPlatformString(
    OperatingSystem os,
    CpuArchitecture architecture,
  ) {
    final osStr = switch (os) {
      OperatingSystem.macos => 'darwin',
      OperatingSystem.linux => 'linux',
      OperatingSystem.windows => 'win32',
      OperatingSystem.fuchsia => 'fuchsia',
      OperatingSystem.unknown => 'unknown',
    };

    final archStr = switch (architecture) {
      CpuArchitecture.x64 => 'x64',
      CpuArchitecture.arm64 => 'arm64',
      CpuArchitecture.arm => 'arm',
      CpuArchitecture.ia32 => 'ia32',
      CpuArchitecture.riscv64 => 'riscv64',
      CpuArchitecture.unknown => 'unknown',
    };

    return '$osStr-$archStr';
  }

  /// All Linux targets that can be cross-compiled from any platform (Dart 3.8+).
  static const _linuxCrossCompileTargets = [
    'linux-arm',
    'linux-arm64',
    'linux-riscv64',
    'linux-x64',
  ];

  /// Returns the list of Dart target platforms that can be built on this platform.
  ///
  /// As of Dart 3.8+, cross-compilation works as follows:
  /// - Each platform can build for its own native OS/architecture
  /// - ALL platforms can cross-compile to ALL Linux variants
  ///   (linux-arm, linux-arm64, linux-riscv64, linux-x64)
  /// - Cross-compilation to macOS or Windows from other OS is NOT supported
  /// - Cross-compilation to different architecture on same OS is NOT supported
  ///   (e.g., darwin-arm64 cannot build darwin-x64)
  static List<String> _getDartTargetPlatforms(
    OperatingSystem os,
    CpuArchitecture architecture,
  ) {
    return switch ((os, architecture)) {
      // macOS arm64: native + all Linux targets
      (OperatingSystem.macos, CpuArchitecture.arm64) => [
          'darwin-arm64',
          ..._linuxCrossCompileTargets,
        ],
      // macOS x64: native + all Linux targets
      (OperatingSystem.macos, CpuArchitecture.x64) => [
          'darwin-x64',
          ..._linuxCrossCompileTargets,
        ],
      // Linux x64: native + all Linux targets (cross-compile within Linux)
      (OperatingSystem.linux, CpuArchitecture.x64) => [
          'linux-x64',
          'linux-arm',
          'linux-arm64',
          'linux-riscv64',
        ],
      // Linux arm64: native + all Linux targets (cross-compile within Linux)
      (OperatingSystem.linux, CpuArchitecture.arm64) => [
          'linux-arm64',
          'linux-arm',
          'linux-riscv64',
          'linux-x64',
        ],
      // Linux arm: native + all Linux targets
      (OperatingSystem.linux, CpuArchitecture.arm) => [
          'linux-arm',
          'linux-arm64',
          'linux-riscv64',
          'linux-x64',
        ],
      // Linux riscv64: native + all Linux targets
      (OperatingSystem.linux, CpuArchitecture.riscv64) => [
          'linux-riscv64',
          'linux-arm',
          'linux-arm64',
          'linux-x64',
        ],
      // Windows x64: native + all Linux targets
      (OperatingSystem.windows, CpuArchitecture.x64) => [
          'win32-x64',
          ..._linuxCrossCompileTargets,
        ],
      // Windows arm64: native + all Linux targets (if supported)
      (OperatingSystem.windows, CpuArchitecture.arm64) => [
          'win32-arm64',
          ..._linuxCrossCompileTargets,
        ],
      // Unknown or unsupported
      _ => [],
    };
  }

  /// Whether this platform can build for the specified target.
  bool canBuildFor(String targetPlatform) {
    return dartTargetPlatforms.contains(targetPlatform);
  }

  @override
  String toString() => platform;
}

/// Global tool context that holds workspace information.
///
/// This class manages the workspace metadata loaded from `.tom_metadata/tom_master.yaml`.
/// It should be initialized before running any tool (except the workspace analyzer).
/// After running the workspace analyzer, the context must be reloaded.
class ToolContext {
  /// Singleton instance
  static ToolContext? _instance;

  /// The loaded workspace information.
  final WorkspaceInfo workspaceInfo;

  /// The workspace root path.
  final String workspacePath;

  /// Platform information for the current system.
  ///
  /// Includes operating system, architecture, platform identifier,
  /// and list of Dart target platforms that can be built.
  final PlatformInfo platformInfo;

  /// Convenience getter for the current operating system.
  OperatingSystem get os => platformInfo.os;

  /// Convenience getter for the current CPU architecture.
  CpuArchitecture get architecture => platformInfo.architecture;

  /// Convenience getter for the platform identifier (e.g., 'darwin-arm64').
  String get platform => platformInfo.platform;

  /// Convenience getter for Dart target platforms buildable on this system.
  List<String> get dartTargetPlatforms => platformInfo.dartTargetPlatforms;

  /// Private constructor.
  ToolContext._({
    required this.workspaceInfo,
    required this.workspacePath,
    required this.platformInfo,
  });

  /// Gets the current tool context instance.
  ///
  /// Throws [StateError] if context has not been initialized.
  static ToolContext get current {
    if (_instance == null) {
      throw StateError(
        'ToolContext has not been initialized. '
        'Call ToolContext.load() before accessing the context.',
      );
    }
    return _instance!;
  }

  /// Whether the context has been initialized.
  static bool get isInitialized => _instance != null;

  /// Loads the workspace context from `.tom_metadata/tom_master.yaml`.
  ///
  /// If [workspacePath] is not provided, uses the current directory's parent
  /// (assuming we're running from a project within the workspace).
  ///
  /// Throws [ToolContextException] if the metadata file is missing or invalid.
  static Future<ToolContext> load({String? workspacePath}) async {
    final wsPath = workspacePath ?? _findWorkspaceRoot();
    final metadataPath = path.join(wsPath, '.tom_metadata', 'tom_master.yaml');
    final metadataFile = File(metadataPath);

    if (!metadataFile.existsSync()) {
      throw ToolContextException(
        'Workspace metadata not found at: $metadataPath\n'
        'Run the workspace analyzer first:\n'
        '  dart run tom_build_cli:ws_analyzer wa-path=$wsPath',
      );
    }

    try {
      final content = await metadataFile.readAsString();
      final yaml = loadYaml(content) as YamlMap?;

      if (yaml == null) {
        throw ToolContextException(
          'Invalid workspace metadata: file is empty or not valid YAML',
        );
      }

      final workspaceInfo = WorkspaceInfo.fromYaml(yaml);
      final platformInfo = PlatformInfo.detect();
      _instance = ToolContext._(
        workspaceInfo: workspaceInfo,
        workspacePath: wsPath,
        platformInfo: platformInfo,
      );

      return _instance!;
    } catch (e) {
      if (e is ToolContextException) rethrow;
      throw ToolContextException(
        'Failed to parse workspace metadata: $e\n'
        'Try regenerating the metadata with:\n'
        '  dart run tom_build_cli:ws_analyzer wa-path=$wsPath',
      );
    }
  }

  /// Reloads the workspace context.
  ///
  /// This should be called after running the workspace analyzer to ensure
  /// the context reflects the latest changes.
  static Future<ToolContext> reload({String? workspacePath}) async {
    _instance = null;
    return load(workspacePath: workspacePath ?? _instance?.workspacePath);
  }

  /// Clears the current context.
  static void clear() {
    _instance = null;
  }

  /// Finds the workspace root by looking for `.tom_metadata` directory.
  static String _findWorkspaceRoot() {
    var current = Directory.current.path;

    // Walk up the directory tree looking for .tom_metadata
    while (current.isNotEmpty && current != '/') {
      if (Directory(path.join(current, '.tom_metadata')).existsSync()) {
        return current;
      }
      current = path.dirname(current);
    }

    // Fall back to parent of current directory
    return path.dirname(Directory.current.path);
  }

  /// Validates that the specified modes are allowed.
  ///
  /// Returns a [ModeValidationResult] with the resolved modes (including implied modes).
  ModeValidationResult validateModes(List<String> requestedModes) {
    final modesConfig = workspaceInfo.workspaceModes;

    if (modesConfig == null) {
      return ModeValidationResult.error(
        'No workspace-modes section found in .tom_metadata/tom_master.yaml.\n'
        'Add a workspace-modes section to your tom_workspace.yaml:\n'
        '\n'
        'workspace-modes:\n'
        '  supported:\n'
        '    - name: development\n'
        '      implies: [ relative_build ]\n'
        '    - name: production\n'
        '    - name: default\n'
        '  default: default',
      );
    }

    final validModeNames = modesConfig.supportedModes.map((m) => m.name).toSet();
    final invalidModes = <String>[];
    final resolvedModes = <String>[];

    for (final mode in requestedModes) {
      if (!validModeNames.contains(mode)) {
        invalidModes.add(mode);
      } else {
        // Add the mode and its implied modes
        if (!resolvedModes.contains(mode)) {
          resolvedModes.add(mode);
        }

        // Add implied modes
        final modeConfig = modesConfig.supportedModes.firstWhere(
          (m) => m.name == mode,
        );
        for (final implied in modeConfig.implies) {
          if (!resolvedModes.contains(implied)) {
            // Insert implied modes before the mode that implies them
            final index = resolvedModes.indexOf(mode);
            resolvedModes.insert(index, implied);
          }
        }
      }
    }

    if (invalidModes.isNotEmpty) {
      return ModeValidationResult.error(
        'Invalid mode(s): ${invalidModes.join(', ')}\n'
        '\n'
        'Valid modes are:\n'
        '${modesConfig.supportedModes.map((m) => '  - ${m.name}${m.implies.isNotEmpty ? ' (implies: ${m.implies.join(', ')})' : ''}').join('\n')}\n'
        '\n'
        'Default mode: ${modesConfig.defaultMode ?? 'none'}',
      );
    }

    return ModeValidationResult.success(resolvedModes);
  }
}

/// Exception thrown when tool context operations fail.
class ToolContextException implements Exception {
  final String message;

  ToolContextException(this.message);

  @override
  String toString() => 'ToolContextException: $message';
}

/// Result of mode validation.
class ModeValidationResult {
  /// Whether the validation was successful.
  final bool isValid;

  /// Error message if validation failed.
  final String? errorMessage;

  /// Resolved modes including implied modes (in order).
  final List<String> resolvedModes;

  ModeValidationResult._({
    required this.isValid,
    this.errorMessage,
    required this.resolvedModes,
  });

  factory ModeValidationResult.success(List<String> resolvedModes) {
    return ModeValidationResult._(
      isValid: true,
      resolvedModes: resolvedModes,
    );
  }

  factory ModeValidationResult.error(String message) {
    return ModeValidationResult._(
      isValid: false,
      errorMessage: message,
      resolvedModes: [],
    );
  }
}
