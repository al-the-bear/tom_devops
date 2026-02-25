import 'dart:io';
import 'package:path/path.dart' as path;

/// Git utilities for version management.
class GitHelper {
  /// The workspace root path.
  final String workspacePath;

  GitHelper({required this.workspacePath});

  /// Checks if the workspace is a git repository.
  bool isGitRepository() {
    final gitDir = Directory(path.join(workspacePath, '.git'));
    return gitDir.existsSync();
  }

  /// Gets the list of changed files since the last tag or commit.
  ///
  /// Uses `git diff --name-only` to detect changes.
  /// Returns paths relative to workspace root.
  Future<List<String>> getChangedFiles({String? since}) async {
    final args = ['diff', '--name-only'];
    if (since != null) {
      args.add(since);
    } else {
      // Get changes since last commit (staged + unstaged)
      args.add('HEAD');
    }

    final result = await Process.run(
      'git',
      args,
      workingDirectory: workspacePath,
    );

    if (result.exitCode != 0) {
      // Try without HEAD (maybe no commits yet)
      final fallbackResult = await Process.run(
        'git',
        ['diff', '--name-only', '--cached'],
        workingDirectory: workspacePath,
      );
      if (fallbackResult.exitCode != 0) {
        return [];
      }
      return _parseFileList(fallbackResult.stdout as String);
    }

    return _parseFileList(result.stdout as String);
  }

  /// Gets files changed since the last version tag for a project.
  ///
  /// Looks for tags matching `<projectName>-v*` pattern.
  Future<List<String>> getChangesSinceLastTag(String projectName) async {
    // Find the last tag for this project
    final tagResult = await Process.run(
      'git',
      ['tag', '--list', '$projectName-v*', '--sort=-v:refname'],
      workingDirectory: workspacePath,
    );

    String? lastTag;
    if (tagResult.exitCode == 0) {
      final tags = _parseFileList(tagResult.stdout as String);
      if (tags.isNotEmpty) {
        lastTag = tags.first;
      }
    }

    // Get changes since that tag (or all changes if no tag)
    final args = ['diff', '--name-only'];
    if (lastTag != null) {
      args.add('$lastTag..HEAD');
    }

    final result = await Process.run(
      'git',
      args,
      workingDirectory: workspacePath,
    );

    if (result.exitCode != 0) {
      return [];
    }

    return _parseFileList(result.stdout as String);
  }

  /// Checks if a project has changes.
  ///
  /// A project has changes if any file under its directory has been modified.
  Future<bool> hasProjectChanges(String projectPath) async {
    final changedFiles = await getChangedFiles();
    final normalizedProjectPath = projectPath.endsWith('/')
        ? projectPath
        : '$projectPath/';

    return changedFiles.any((file) => file.startsWith(normalizedProjectPath));
  }

  /// Creates a git tag.
  Future<bool> createTag(String tagName, {String? message}) async {
    final args = ['tag'];
    if (message != null) {
      args.addAll(['-m', message]);
    }
    args.add(tagName);

    final result = await Process.run(
      'git',
      args,
      workingDirectory: workspacePath,
    );

    return result.exitCode == 0;
  }

  /// Commits all changes with the given message.
  Future<bool> commitAll(String message) async {
    // Stage all changes
    final addResult = await Process.run(
      'git',
      ['add', '-A'],
      workingDirectory: workspacePath,
    );

    if (addResult.exitCode != 0) {
      return false;
    }

    // Commit
    final commitResult = await Process.run(
      'git',
      ['commit', '-m', message],
      workingDirectory: workspacePath,
    );

    return commitResult.exitCode == 0;
  }

  /// Parses git output into a list of file paths.
  List<String> _parseFileList(String output) {
    return output
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}
