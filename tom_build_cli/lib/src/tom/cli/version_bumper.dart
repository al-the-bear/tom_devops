import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Bumps versions in pubspec.yaml files.
class VersionBumper {
  /// The workspace root path.
  final String workspacePath;

  /// Whether to run in dry-run mode.
  final bool dryRun;

  /// Whether to print verbose output.
  final bool verbose;

  VersionBumper({
    required this.workspacePath,
    this.dryRun = false,
    this.verbose = false,
  });

  /// Bumps the version in a project's pubspec.yaml.
  ///
  /// Returns the new version string, or null if bump failed.
  Future<VersionBumpResult> bumpVersion(
    String projectPath, {
    required BumpType bumpType,
  }) async {
    final pubspecPath = path.join(workspacePath, projectPath, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      return VersionBumpResult.failure(
        projectPath: projectPath,
        error: 'pubspec.yaml not found at $pubspecPath',
      );
    }

    try {
      final content = pubspecFile.readAsStringSync();
      final yaml = loadYaml(content);

      if (yaml is! Map || !yaml.containsKey('version')) {
        return VersionBumpResult.failure(
          projectPath: projectPath,
          error: 'No version field in pubspec.yaml',
        );
      }

      final currentVersionStr = yaml['version'].toString();
      final currentVersion = Version.parse(currentVersionStr);

      // Calculate new version
      final newVersion = _bumpVersion(currentVersion, bumpType);
      final newVersionStr = newVersion.toString();

      if (dryRun) {
        return VersionBumpResult.success(
          projectPath: projectPath,
          oldVersion: currentVersionStr,
          newVersion: newVersionStr,
          dryRun: true,
        );
      }

      // Update the file
      final newContent = _updateVersionInYaml(content, newVersionStr);
      pubspecFile.writeAsStringSync(newContent);

      return VersionBumpResult.success(
        projectPath: projectPath,
        oldVersion: currentVersionStr,
        newVersion: newVersionStr,
        dryRun: false,
      );
    } catch (e) {
      return VersionBumpResult.failure(
        projectPath: projectPath,
        error: 'Failed to bump version: $e',
      );
    }
  }

  /// Bumps a version according to the bump type.
  Version _bumpVersion(Version current, BumpType type) {
    switch (type) {
      case BumpType.major:
        return current.nextMajor;
      case BumpType.minor:
        return current.nextMinor;
      case BumpType.patch:
        return current.nextPatch;
      case BumpType.build:
        // Increment build number
        final buildNumber = current.build.isEmpty
            ? 1
            : (int.tryParse(current.build.first.toString()) ?? 0) + 1;
        return Version(
          current.major,
          current.minor,
          current.patch,
          build: buildNumber.toString(),
        );
    }
  }

  /// Updates the version field in YAML content while preserving formatting.
  String _updateVersionInYaml(String content, String newVersion) {
    // Simple regex replacement to preserve formatting
    final versionRegex = RegExp(r'^version:\s*[\d.]+.*$', multiLine: true);
    return content.replaceFirst(versionRegex, 'version: $newVersion');
  }
}

/// The type of version bump.
enum BumpType {
  major,
  minor,
  patch,
  build,
}

/// Parses a bump type from string.
BumpType parseBumpType(String? value) {
  switch (value?.toLowerCase()) {
    case 'major':
      return BumpType.major;
    case 'minor':
      return BumpType.minor;
    case 'build':
      return BumpType.build;
    case 'patch':
    default:
      return BumpType.patch;
  }
}

/// Result of a version bump operation.
class VersionBumpResult {
  final String projectPath;
  final bool success;
  final String? oldVersion;
  final String? newVersion;
  final String? error;
  final bool dryRun;

  const VersionBumpResult._({
    required this.projectPath,
    required this.success,
    this.oldVersion,
    this.newVersion,
    this.error,
    this.dryRun = false,
  });

  factory VersionBumpResult.success({
    required String projectPath,
    required String oldVersion,
    required String newVersion,
    required bool dryRun,
  }) {
    return VersionBumpResult._(
      projectPath: projectPath,
      success: true,
      oldVersion: oldVersion,
      newVersion: newVersion,
      dryRun: dryRun,
    );
  }

  factory VersionBumpResult.failure({
    required String projectPath,
    required String error,
  }) {
    return VersionBumpResult._(
      projectPath: projectPath,
      success: false,
      error: error,
    );
  }
}
