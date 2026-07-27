/// What a path in a repository is.
enum GitHubContentType {
  file,
  dir,
  symlink,
  submodule;

  static GitHubContentType parse(String raw) => switch (raw) {
        'file' => GitHubContentType.file,
        'dir' => GitHubContentType.dir,
        'symlink' => GitHubContentType.symlink,
        'submodule' => GitHubContentType.submodule,
        _ => throw ArgumentError('Unknown GitHub content type: $raw'),
      };
}

/// One entry from the repository contents API — a file or a directory child.
///
/// [sha] is the git blob sha for a file, and is what the contents API requires
/// when overwriting or deleting: it is the API's own optimistic-concurrency
/// token for a single path.
class GitHubContentEntry {
  final String name;
  final String path;
  final GitHubContentType type;
  final String sha;
  final int size;
  final String? downloadUrl;

  const GitHubContentEntry({
    required this.name,
    required this.path,
    required this.type,
    required this.sha,
    required this.size,
    this.downloadUrl,
  });

  factory GitHubContentEntry.fromJson(Map<String, dynamic> json) =>
      GitHubContentEntry(
        name: json['name'] as String,
        path: json['path'] as String,
        type: GitHubContentType.parse(json['type'] as String),
        sha: json['sha'] as String? ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        downloadUrl: json['download_url'] as String?,
      );

  bool get isFile => type == GitHubContentType.file;
  bool get isDirectory => type == GitHubContentType.dir;

  @override
  String toString() => 'GitHubContentEntry(${type.name} $path, sha: $sha)';
}

/// The commit a contents-API write produced.
class GitHubContentWriteResult {
  /// The sha of the blob that was written; `null` for a delete.
  final String? contentSha;

  /// The sha of the commit the write created.
  final String commitSha;

  const GitHubContentWriteResult({
    required this.contentSha,
    required this.commitSha,
  });

  factory GitHubContentWriteResult.fromJson(Map<String, dynamic> json) =>
      GitHubContentWriteResult(
        contentSha:
            (json['content'] as Map<String, dynamic>?)?['sha'] as String?,
        commitSha:
            (json['commit'] as Map<String, dynamic>)['sha'] as String,
      );
}
