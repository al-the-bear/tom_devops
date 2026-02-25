/// Build order calculation for Tom workspace projects.
///
/// Calculates the topologically sorted build order based on `build-after`
/// dependencies between projects.
///
/// ## Features
///
/// - Topological sort based on `build-after` declarations
/// - Circular dependency detection with clear error messages
/// - Action-specific build order calculation
/// - Support for projects with no dependencies
///
/// ## Usage
///
/// ```dart
/// final calculator = BuildOrderCalculator();
/// final order = calculator.calculateBuildOrder({
///   'core': BuildOrderProject(name: 'core', buildAfter: []),
///   'app': BuildOrderProject(name: 'app', buildAfter: ['core']),
/// });
/// // order == ['core', 'app']
/// ```
library;

/// A project with its build-after dependencies.
class BuildOrderProject {
  /// Project name.
  final String name;

  /// List of project names that must be built before this one.
  final List<String> buildAfter;

  /// Creates a build order project.
  const BuildOrderProject({
    required this.name,
    this.buildAfter = const [],
  });
}

/// Result of build order calculation.
class BuildOrderResult {
  /// The topologically sorted list of project names.
  final List<String> order;

  /// Whether all projects were successfully ordered.
  final bool success;

  /// Error message if ordering failed.
  final String? error;

  /// Projects involved in circular dependency (if any).
  final List<String>? circularPath;

  const BuildOrderResult._({
    required this.order,
    required this.success,
    this.error,
    this.circularPath,
  });

  /// Creates a successful result.
  factory BuildOrderResult.success(List<String> order) {
    return BuildOrderResult._(order: order, success: true);
  }

  /// Creates an error result.
  factory BuildOrderResult.error(String message, {List<String>? circularPath}) {
    return BuildOrderResult._(
      order: const [],
      success: false,
      error: message,
      circularPath: circularPath,
    );
  }
}

/// Exception thrown when circular dependency is detected.
class CircularDependencyException implements Exception {
  /// Error message describing the circular dependency.
  final String message;

  /// The cycle path (e.g., ['a', 'b', 'c', 'a']).
  final List<String> cyclePath;

  /// Creates a circular dependency exception.
  const CircularDependencyException({
    required this.message,
    required this.cyclePath,
  });

  @override
  String toString() => 'CircularDependencyException: $message\n'
      'Cycle: ${cyclePath.join(" -> ")}';
}

/// Calculates build order for projects based on their dependencies.
class BuildOrderCalculator {
  /// Calculates the build order for a set of projects.
  ///
  /// Uses Kahn's algorithm for topological sorting.
  /// Returns projects in order such that each project comes after
  /// all projects it depends on.
  ///
  /// [projects] is a map of project name to [BuildOrderProject].
  ///
  /// Throws [CircularDependencyException] if a cycle is detected.
  List<String> calculateBuildOrder(Map<String, BuildOrderProject> projects) {
    if (projects.isEmpty) return [];

    // Build adjacency list and in-degree count
    final adjacency = <String, List<String>>{};
    final inDegree = <String, int>{};

    // Initialize all projects
    for (final name in projects.keys) {
      adjacency[name] = [];
      inDegree[name] = 0;
    }

    // Build the graph
    // If A has buildAfter: [B], then B -> A (B must be built before A)
    for (final project in projects.values) {
      for (final dependency in project.buildAfter) {
        if (!projects.containsKey(dependency)) {
          throw CircularDependencyException(
            message: 'Project "${project.name}" depends on unknown project "$dependency"',
            cyclePath: [project.name, dependency],
          );
        }
        adjacency[dependency]!.add(project.name);
        inDegree[project.name] = inDegree[project.name]! + 1;
      }
    }

    // Kahn's algorithm
    final queue = <String>[];
    final result = <String>[];

    // Start with projects that have no dependencies
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    // Sort queue for deterministic order
    queue.sort();

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);

      // Collect and sort neighbors for deterministic order
      final neighbors = List<String>.from(adjacency[current]!);
      neighbors.sort();

      for (final neighbor in neighbors) {
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        if (inDegree[neighbor] == 0) {
          // Insert in sorted position for deterministic order
          var insertIndex = 0;
          while (insertIndex < queue.length && queue[insertIndex].compareTo(neighbor) < 0) {
            insertIndex++;
          }
          queue.insert(insertIndex, neighbor);
        }
      }
    }

    // Check for cycles
    if (result.length != projects.length) {
      final remaining = projects.keys.where((p) => !result.contains(p)).toList();
      final cycle = _findCycle(remaining, projects);
      throw CircularDependencyException(
        message: 'Circular dependency detected',
        cyclePath: cycle,
      );
    }

    return result;
  }

  /// Calculates build order and returns a result object (non-throwing).
  ///
  /// Use this method when you want to handle errors without exceptions.
  BuildOrderResult calculateBuildOrderSafe(Map<String, BuildOrderProject> projects) {
    try {
      final order = calculateBuildOrder(projects);
      return BuildOrderResult.success(order);
    } on CircularDependencyException catch (e) {
      return BuildOrderResult.error(e.message, circularPath: e.cyclePath);
    }
  }

  /// Calculates action-specific build order.
  ///
  /// Some actions may have different dependency requirements.
  /// This method calculates the order for a specific action.
  ///
  /// [projects] is a map of project name to [BuildOrderProject].
  /// [action] is the action name to calculate order for.
  /// [actionDeps] is an optional map of project to action-specific dependencies.
  List<String> calculateActionOrder({
    required Map<String, BuildOrderProject> projects,
    required String action,
    Map<String, List<String>>? actionDeps,
  }) {
    // If no action-specific deps, use normal build order
    if (actionDeps == null || actionDeps.isEmpty) {
      return calculateBuildOrder(projects);
    }

    // Create modified projects with action-specific dependencies
    final modifiedProjects = <String, BuildOrderProject>{};
    for (final entry in projects.entries) {
      final actionSpecific = actionDeps[entry.key] ?? [];
      final allDeps = {...entry.value.buildAfter, ...actionSpecific}.toList();
      modifiedProjects[entry.key] = BuildOrderProject(
        name: entry.key,
        buildAfter: allDeps,
      );
    }

    return calculateBuildOrder(modifiedProjects);
  }

  /// Finds a cycle in the remaining unprocessed projects.
  List<String> _findCycle(List<String> remaining, Map<String, BuildOrderProject> projects) {
    if (remaining.isEmpty) return [];

    final visited = <String>{};
    final recursionStack = <String>[];

    bool dfs(String node) {
      if (recursionStack.contains(node)) {
        // Found cycle
        return true;
      }

      if (visited.contains(node)) return false;

      visited.add(node);
      recursionStack.add(node);

      final project = projects[node];
      if (project != null) {
        for (final dep in project.buildAfter) {
          if (remaining.contains(dep) && dfs(dep)) {
            return true;
          }
        }
      }

      recursionStack.removeLast();
      return false;
    }

    for (final start in remaining) {
      recursionStack.clear();
      if (dfs(start)) {
        // Return the cycle path
        return [...recursionStack, recursionStack.first];
      }
    }

    // Fallback: return remaining projects as cycle indication
    return remaining;
  }

  /// Validates that all dependencies exist.
  ///
  /// Returns a list of validation errors, or empty list if valid.
  List<String> validateDependencies(Map<String, BuildOrderProject> projects) {
    final errors = <String>[];

    for (final project in projects.values) {
      for (final dep in project.buildAfter) {
        if (!projects.containsKey(dep)) {
          errors.add('Project "${project.name}" depends on unknown project "$dep"');
        }
      }
    }

    return errors;
  }

  /// Creates BuildOrderProject map from TomProject-style map.
  ///
  /// Extracts `build-after` from project configuration maps.
  static Map<String, BuildOrderProject> fromProjectConfigs(
    Map<String, Map<String, dynamic>> configs,
  ) {
    final result = <String, BuildOrderProject>{};

    for (final entry in configs.entries) {
      final name = entry.key;
      final config = entry.value;

      final buildAfter = <String>[];
      if (config['build-after'] is List) {
        for (final dep in config['build-after'] as List) {
          buildAfter.add(dep.toString());
        }
      }

      result[name] = BuildOrderProject(name: name, buildAfter: buildAfter);
    }

    return result;
  }
}
