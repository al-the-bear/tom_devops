/// Configuration loading for issuekit.
///
/// Reads configuration from the `issuekit:` section of `buildkit_master.yaml`
/// (workspace level) and the project's `buildkit.yaml` (project level).
library;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:tom_build_base/tom_build_base.dart'
    show findWorkspaceRootOrNull, kBuildkitMasterYaml;
import 'package:yaml/yaml.dart';

/// Issue tracking configuration (`issuekit: issue_tracking:` in
/// `buildkit_master.yaml`).
class IssueTrackingConfig {
  /// Constructor.
  const IssueTrackingConfig({
    required this.issuesRepo,
    required this.testsRepo,
    this.defaultSeverity = 'normal',
    this.defaultReporter,
  });

  /// The GitHub repository for issues (e.g., 'al-the-bear/tom_issues').
  final String issuesRepo;

  /// The GitHub repository for test entries (e.g., 'al-the-bear/tom_tests').
  final String testsRepo;

  /// Default severity for new issues.
  final String defaultSeverity;

  /// Default reporter name.
  final String? defaultReporter;

  /// Parse from a map (from YAML).
  static IssueTrackingConfig? tryParse(Map<String, dynamic>? map) {
    if (map == null) return null;

    final issuesRepo = map['issues_repo'] as String?;
    final testsRepo = map['tests_repo'] as String?;

    if (issuesRepo == null || testsRepo == null) {
      return null;
    }

    return IssueTrackingConfig(
      issuesRepo: issuesRepo,
      testsRepo: testsRepo,
      defaultSeverity: (map['default_severity'] as String?) ?? 'normal',
      defaultReporter: map['default_reporter'] as String?,
    );
  }

  /// Get the owner component of a repo string (e.g., 'al-the-bear' from
  /// 'al-the-bear/tom_issues').
  static String? getOwner(String repoString) {
    final parts = repoString.split('/');
    if (parts.length != 2) return null;
    return parts[0];
  }

  /// Get the repo name component of a repo string (e.g., 'tom_issues' from
  /// 'al-the-bear/tom_issues').
  static String? getRepoName(String repoString) {
    final parts = repoString.split('/');
    if (parts.length != 2) return null;
    return parts[1];
  }

  /// Get owner from issues repo.
  String? get issuesOwner => getOwner(issuesRepo);

  /// Get repo name from issues repo.
  String? get issuesRepoName => getRepoName(issuesRepo);

  /// Get owner from tests repo.
  String? get testsOwner => getOwner(testsRepo);

  /// Get repo name from tests repo.
  String? get testsRepoName => getRepoName(testsRepo);
}

/// Project configuration: the identity at the top of the project's
/// `buildkit.yaml`.
class ProjectConfig {
  /// Constructor.
  const ProjectConfig({required this.projectId, this.projectName});

  /// The project ID (2-4 uppercase characters, e.g., 'D4', 'BK', 'IK').
  final String projectId;

  /// The full project name.
  final String? projectName;

  /// Parse from a map (from YAML).
  static ProjectConfig? tryParse(Map<String, dynamic>? map) {
    if (map == null) return null;

    final projectId = map['project_id'] as String?;
    if (projectId == null) return null;

    return ProjectConfig(
      projectId: projectId,
      projectName: map['name'] as String?,
    );
  }

  /// Validate the project ID format.
  ///
  /// Returns true if the ID is 2-4 uppercase characters.
  bool get isValidProjectId {
    if (projectId.length < 2 || projectId.length > 4) return false;
    return RegExp(r'^[A-Z0-9]+$').hasMatch(projectId);
  }
}

/// GitHub authentication configuration.
class GitHubAuthConfig {
  /// Constructor.
  const GitHubAuthConfig({
    this.token,
    this.tokenFile,
    this.envVariable = 'GITHUB_TOKEN',
  });

  /// Direct token value (not recommended for storage in config files).
  final String? token;

  /// Path to a file containing the token.
  final String? tokenFile;

  /// Environment variable name to check for token (default: GITHUB_TOKEN).
  final String envVariable;

  /// Parse from a map (from YAML).
  static GitHubAuthConfig? tryParse(Map<String, dynamic>? map) {
    if (map == null) return GitHubAuthConfig();

    return GitHubAuthConfig(
      token: map['token'] as String?,
      tokenFile: map['token_file'] as String?,
      envVariable: (map['env_variable'] as String?) ?? 'GITHUB_TOKEN',
    );
  }

  /// Resolve the actual token value.
  ///
  /// Resolution order:
  /// 1. Direct token value (if set)
  /// 2. Environment variable (GITHUB_TOKEN by default)
  /// 3. Token file contents (if file exists)
  ///
  /// Returns null if no token can be resolved.
  String? resolveToken() {
    // 1. Direct token
    if (token != null && token!.isNotEmpty) {
      return token;
    }

    // 2. Environment variable
    final envToken = Platform.environment[envVariable];
    if (envToken != null && envToken.isNotEmpty) {
      return envToken;
    }

    // 3. Token file
    if (tokenFile != null) {
      final file = File(tokenFile!);
      if (file.existsSync()) {
        final contents = file.readAsStringSync().trim();
        if (contents.isNotEmpty) {
          return contents;
        }
      }
    }

    return null;
  }
}

/// Complete issuekit configuration.
class IssueKitConfig {
  /// Constructor.
  const IssueKitConfig({
    this.issueTracking,
    this.auth,
    this.projectConfigs = const {},
  });

  /// Issue tracking configuration (`issuekit: issue_tracking:`).
  final IssueTrackingConfig? issueTracking;

  /// GitHub authentication configuration.
  final GitHubAuthConfig? auth;

  /// Project configurations by project path.
  final Map<String, ProjectConfig> projectConfigs;

  /// Check if the configuration is valid for issuekit operations.
  bool get isValid => issueTracking != null;

  /// Get the resolved GitHub token.
  String? get token => auth?.resolveToken();

  /// The workspace issuekit works in, seen from [startDirectory]:
  /// `TOM_WORKSPACE_ROOT` from [environment] when set, else the nearest
  /// directory holding `buildkit_master.yaml`, else [startDirectory].
  static String workspaceRootFor(
    String startDirectory,
    Map<String, String> environment,
  ) {
    final explicit = environment['TOM_WORKSPACE_ROOT'];
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return findWorkspaceRootOrNull(startDirectory) ?? startDirectory;
  }

  /// Load configuration from a workspace root.
  ///
  /// Reads the `issuekit:` section of `buildkit_master.yaml`:
  ///
  /// ```yaml
  /// issuekit:
  ///   issue_tracking:
  ///     issues_repo: owner/issues
  ///     tests_repo: owner/tests
  ///   github_auth:
  ///     token_file: ~/.tom/github_token
  /// ```
  static Future<IssueKitConfig> load(String workspaceRoot) async {
    final master = File(path.join(workspaceRoot, kBuildkitMasterYaml));

    IssueTrackingConfig? issueTracking;
    GitHubAuthConfig? auth;

    if (master.existsSync()) {
      final yaml = loadYaml(await master.readAsString());
      final section = yaml is YamlMap ? yaml['issuekit'] : null;
      if (section is YamlMap) {
        issueTracking = IssueTrackingConfig.tryParse(
          _plainMap(section['issue_tracking']),
        );
        auth = GitHubAuthConfig.tryParse(_plainMap(section['github_auth']));
      }
    }

    // If no auth config, use defaults
    auth ??= const GitHubAuthConfig();

    return IssueKitConfig(issueTracking: issueTracking, auth: auth);
  }

  /// A YAML map as a plain `Map<String, dynamic>`, or null.
  static Map<String, dynamic>? _plainMap(Object? value) => value is YamlMap
      ? {for (final e in value.entries) '${e.key}': e.value}
      : null;

  /// Load project configuration from a project directory.
  ///
  /// Reads `project_id` and `name` from the project's `buildkit.yaml`.
  static Future<ProjectConfig?> loadProject(String projectPath) async {
    final projectYaml = File(path.join(projectPath, 'buildkit.yaml'));
    if (!projectYaml.existsSync()) return null;

    final yaml = loadYaml(await projectYaml.readAsString());
    if (yaml is! YamlMap) return null;
    return ProjectConfig.tryParse({
      if (yaml['project_id'] != null) 'project_id': '${yaml['project_id']}',
      if (yaml['name'] != null) 'name': '${yaml['name']}',
    });
  }
}
