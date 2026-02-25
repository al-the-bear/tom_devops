# Tom Placeholders & D4rt Guide

> **Note:** For a concise syntax reference, see [doc/tom_user_reference.md](../../doc/tom_user_reference.md). This guide provides detailed implementation information.

This guide covers the Tom Build placeholder resolution and D4rt script execution systems. These systems work together to provide dynamic string substitution and script execution within the Tom workspace.

## Table of Contents

- [Overview](#overview)
- [Placeholder Syntax](#placeholder-syntax)
  - [Generation-Time Placeholders](#generation-time-placeholders)
  - [Runtime-Only Placeholders](#runtime-only-placeholders)
- [Placeholder Resolution API](#placeholder-resolution-api)
  - [replacePlaceholders](#replaceplaceholders)
  - [replacePlaceholdersSync](#replaceplaceholderssync)
  - [PlaceholderResolver Class](#placeholderresolver-class)
- [D4rt System](#d4rt-system)
  - [D4rtInstance](#d4rtinstance)
  - [Context Providers](#context-providers)
  - [Script Execution](#script-execution)
  - [Synchronous Execution](#synchronous-execution)
- [Bridge System](#bridge-system)
  - [TomBuildBridge](#tombuildbridge)
  - [ScriptingBridge](#scriptingbridge)
  - [Available Bridges](#available-bridges)
- [Common Patterns](#common-patterns)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

---

## Overview

The Tom Build system provides two complementary approaches for dynamic content:

| System | Purpose | Use Case |
|--------|---------|----------|
| **Placeholders** | String substitution | Config files, templates, YAML values |
| **D4rt** | Full script execution | Complex logic, build automation, custom actions |

### Resolution Stages

Tom CLI processes configuration through three phases:

| Phase | When | What Resolves |
|-------|------|---------------|
| **Generation** | Writing tom_master*.yaml | `[[...]]`, `[{...}]` placeholders |
| **Runtime** | After YAML loaded, before commands | `$VAL{...}`, `$ENV{...}`, `$D4{...}`, `$D4S{...}`, `$D4M{...}`, `$GEN{...}`, `$VSCODE{...}` |
| **Execution** | Commands run one by one | `tom:`, `vscode:`, `dartscript:`, shell, reflection commands |

### When to Use Each

- **`[[...]]`, `[{...}]`**: Config values needed in generated files (generation + runtime)
- **`$VAL{}`, `$ENV{}`, `$GEN{}`**: Values resolved fresh before each action (runtime only)
- **`$D4{}`**: Dynamic computation at runtime
- **D4rt Scripts**: Complex computation, conditional logic, file operations, API calls

### Dependencies

- `tom_d4rt` - The D4rt interpreter package
- `tom_build/scripting` - Shell, filesystem, and utility helpers
- `tom_build/tools` - Placeholder resolution utilities

---

## Placeholder Syntax

Tom supports two categories of placeholders based on when they are resolved:

### Generation-Time Placeholders

These are resolved during `tom_master*.yaml` construction AND at runtime:

| Syntax | Description | Example |
|--------|-------------|---------|
| `[[VAR]]` | Environment variable | `[[HOME]]`, `[[AWS_REGION:-us-east-1]]` |
| `[{path}]` | Tom Master data path | `[{packages.tom_core.version}]` |

### Runtime-Only Placeholders

These are resolved once before executing each action (NOT at generation time):

| Syntax | Description | Example |
|--------|-------------|---------|
| `$VAL{key}` | Config value reference | `$VAL{deps.path:-^1.9.0}` |
| `$ENV{VAR}` | Environment variable | `$ENV{HOME}`, `$ENV{PORT:-8080}` |
| `$D4{expr}` | D4rt expression | `$D4{version.major + 1}` |
| `$GEN{path}` | Generator pattern | `$GEN{projects.*.name;,}` |

### Environment Variable Placeholders

```yaml
config:
  api:
    url: https://api.example.com
    
# Usage
endpoint: ${config.api.url}/v1
# Result: https://api.example.com/v1
```

### Environment Variable Placeholders

Access system and `.env` file variables:

```yaml
# Syntax: [[VARIABLE_NAME]]
home_dir: [[HOME]]
api_key: [[API_KEY]]
```

**With .env file:**

```bash
# .env
API_KEY=secret123
DATABASE_URL=postgres://localhost/db
```

```yaml
connection: [[DATABASE_URL]]
# Result: postgres://localhost/db
```

### Tom Master Data Placeholders

Access workspace metadata from `tom_master.yaml`:

```yaml
# Syntax: [{path.to.value}]
# With optional default: [{path.to.value:-default}]

# Simple path
version: [{packages.tom_core.version}]

# With default value
author: [{metadata.author:-Unknown}]
```

**Generator patterns with wildcards:**

```yaml
# Get all package versions (comma-separated)
all_versions: [{packages.*.version}]
# Result: 1.0.0,2.1.0,0.5.0

# Custom separator
versions_list: [{packages.*.version:-none: | }]
# Result: 1.0.0 | 2.1.0 | 0.5.0
```

**Filter patterns:**

```yaml
# Filter by property
publishable: [{packages.[publishable:true].name:,}]
# Result: tom_core,tom_build,tom_cli

# Filter with wildcards
tom_packages: [{packages.[name:tom_*].version:,}]
# Result: 1.0.0,2.1.0
```

### D4rt Expression Placeholders

Execute Dart expressions inline:

```yaml
# Syntax: $D4{expression}

# Simple expression
next_version: $D4{version.major + 1}.0.0

# Method call
formatted: $D4{projectName.toUpperCase()}

# Complex expression
build_id: $D4{DateTime.now().millisecondsSinceEpoch}
```

**D4rt script types:**

| Syntax | Type | Description |
|--------|------|-------------|
| `$D4{expr}` | Expression | Single expression, returns value |
| `$D4S{file.dart}` | Script file | Execute a .dart file from tom_scripts |
| `$D4S\n...` | Inline script | Multiline script with `main()` |
| `$D4M\n...` | Method block | Multiline method body |

---

## Placeholder Resolution API

### replacePlaceholders

Async function to resolve all placeholder types:

```dart
import 'package:tom_build/tools.dart';

Future<String> replacePlaceholders(
  String withPlaceholders, {
  D4rtInstance? instance,
  D4rtContextProviderDefaults? context,
  Map<String, dynamic> yamlValues = const {},
  bool resolveD4rt = true,
});
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `withPlaceholders` | String | Input string with placeholders |
| `instance` | D4rtInstance? | D4rt instance for expression evaluation |
| `context` | D4rtContextProviderDefaults? | Context provider for D4rt setup |
| `yamlValues` | Map<String, dynamic> | Values for `${key}` substitution |
| `resolveD4rt` | bool | If false, skip D4rt placeholders |

**Example:**

```dart
final result = await replacePlaceholders(
  'Hello ${name}, version $D4{major + 1}.${minor}',
  yamlValues: {'name': 'World', 'minor': '0'},
  instance: d4rtInstance,
);
// Result: 'Hello World, version 2.0'
```

### replacePlaceholdersSync

Synchronous version that throws if D4rt returns a Future:

```dart
String replacePlaceholdersSync(
  String withPlaceholders, {
  D4rtInstance? instance,
  D4rtContextProviderDefaults? context,
  Map<String, dynamic> yamlValues = const {},
  bool resolveD4rt = true,
  String? sourceLocation,
});
```

**Throws:** `D4rtSyncExecutionException` if any D4rt expression returns a Future.

```dart
try {
  final result = replacePlaceholdersSync(
    'Value: $D4{asyncOperation()}',
    instance: d4rt,
    sourceLocation: 'config.yaml:line 42',
  );
} on D4rtSyncExecutionException catch (e) {
  print(e);
  // D4rtSyncExecutionException: Future results are not allowed
  // in synchronous script execution (from config.yaml:line 42).
}
```

### PlaceholderResolver Class

Full-featured resolver for Tom Master data:

```dart
import 'package:tom_build/tools.dart';

final resolver = PlaceholderResolver(
  data: tomMasterData,           // Map from tom_master.yaml
  environment: customEnv,         // Optional: override Platform.environment
  d4rtEvaluator: evaluator,       // Optional: D4rt expression callback
);

// Resolve all placeholders
final result = await resolver.resolve(
  'Package: [{packages.tom_core.name}], Home: [[HOME]]'
);
```

**Supported syntax:**

```dart
// Simple path
await resolver.resolve('[{packages.tom_core.version}]');

// With default
await resolver.resolve('[{missing.value:-fallback}]');

// Generator pattern
await resolver.resolve('[{packages.*.name:, }]');

// Filter pattern
await resolver.resolve('[{packages.[publishable:true].name}]');

// Environment variable
await resolver.resolve('[[HOME]]/workspace');

// D4rt expression (requires d4rtEvaluator)
await resolver.resolve('[{ return 1 + 1; }]');
```

---

## D4rt System

### D4rtInstance

Managed D4rt interpreter instance with bridge registration:

```dart
import 'package:tom_build/dartscript.dart';

// Create instance with all bridges
final d4rt = D4rtInstance.create();

// With workspace context (enables `tom` global object)
final d4rt = D4rtInstance.create(
  workspace: myWorkspace,
  workspaceContext: myContext,
  currentProject: myProject,
  workspacePath: '/path/to/workspace',
);

// Execute scripts
final result = await d4rt.executeScript('''
  int main() {
    return 42;
  }
''');

// Evaluate expressions
await d4rt.prepareForScripts();  // Required for imports
final value = await d4rt.evaluate('1 + 1');

// Clean up
d4rt.dispose();
```

**Key Methods:**

| Method | Description |
|--------|-------------|
| `evaluate(String)` | Evaluate expression, return result |
| `evaluateSync(String)` | Synchronous evaluation |
| `executeScript(String)` | Execute full script with `main()` |
| `executeScriptSync(String)` | Synchronous script execution |
| `prepareForScripts()` | Set up imports for `evaluate()` |
| `prepareForScriptsSync()` | Synchronous preparation |
| `setContext(key, value)` | Inject context variable |
| `setContextAll(Map)` | Inject multiple context variables |
| `dispose()` | Release resources |

### Context Providers

Abstract interface for pluggable context injection:

#### ActionContextProvider

For action execution with full project context:

```dart
final provider = ActionContextProvider(
  workspacePath: '/path/to/workspace',
  projectName: 'my_project',
  actionName: 'build',
  workspace: workspace,
  currentProject: project,
  resolvedModes: modes,  // From tom_master_<action>.yaml
);

// Context variables available:
// - workspacePath, projectName, actionName
// - workspace (YAML map), project (YAML map)
// - modes (List<String>), modeTypeValues (Map)
```

#### WorkspaceActionContextProvider

For pre-action and post-action scripts (no project context):

```dart
final provider = WorkspaceActionContextProvider(
  workspacePath: '/path/to/workspace',
  actionName: 'build',
  phase: ActionPhase.pre,  // or ActionPhase.post
  workspace: workspace,
  resolvedModes: globalModes,
);

// Context variables available:
// - workspacePath, actionName, phase
// - workspace (YAML map)
// - modes (List<String>), modeTypeValues (Map)
// NOTE: No projectName or project - runs at workspace level
```

#### TemplateContextProvider

For template processing:

```dart
final provider = TemplateContextProvider(
  workspace: workspace,
  project: project,
  resolvedModes: modes,
);

// Context variables: workspace, project, modes, modeTypeValues
```

#### StandaloneContextProvider

For custom/ad-hoc usage:

```dart
final provider = StandaloneContextProvider({
  'customKey': 'customValue',
  'config': {'setting': true},
});
```

#### CompositeContextProvider

Combine multiple providers:

```dart
final provider = CompositeContextProvider([
  ActionContextProvider(...),
  StandaloneContextProvider({'override': 'value'}),
]);
// Later providers override earlier ones for duplicate keys
```

### Script Execution

#### Execute vs Evaluate

```dart
// executeScript: Full script with main()
final result = await d4rt.executeScript('''
  import 'package:tom_build/scripting.dart';
  
  String main() {
    return Shell.capture('pwd');
  }
''');

// evaluate: Simple expression (requires prepareForScripts first)
await d4rt.prepareForScripts();
final result = await d4rt.evaluate('1 + 1');  // 2
```

#### Return Values

```dart
// Typed main() returns directly
await d4rt.executeScript('int main() => 42');        // 42
await d4rt.executeScript('String main() => "hi"');   // "hi"
await d4rt.executeScript('void main() {}');          // null

// Async main() is automatically awaited
await d4rt.executeScript('''
  Future<int> main() async {
    await Future.delayed(Duration(milliseconds: 100));
    return 42;
  }
''');  // 42 (not a Future!)
```

### Synchronous Execution

All async methods have sync counterparts:

```dart
// Synchronous methods
d4rt.prepareForScriptsSync();
final result = d4rt.evaluateSync('1 + 1');
final scriptResult = d4rt.executeScriptSync('int main() => 42');

// With source location for error messages
final result = d4rt.evaluateSync(
  'someExpression',
  sourceLocation: 'tom_project.yaml:actions.build[0], line 42',
);
```

**Future Detection:**

```dart
try {
  d4rt.executeScriptSync('''
    Future<int> main() async => 42;
  ''', sourceLocation: 'pre-action script');
} on D4rtSyncExecutionException catch (e) {
  print(e);
  // D4rtSyncExecutionException: Future results are not allowed
  // in synchronous script execution (from pre-action script).
}
```

---

## Bridge System

### TomBuildBridge

Unified entry point for all tom_build bridges:

```dart
import 'package:tom_d4rt/d4rt.dart';
import 'package:tom_build/dartscript.dart';

final interpreter = D4rt();
TomBuildBridge.registerAllBridges(interpreter);

// Statistics
print(TomBuildBridge.bridgedClassCount);  // 35
print(TomBuildBridge.moduleNames);        // [AnalyzerBridge, TomBridge, ...]
```

### ScriptingBridge

Shell-script-like functionality in D4rt:

```dart
import 'package:tom_build/scripting.dart';

void main() {
  // Shell commands
  Shell.run('dart analyze');
  final output = Shell.capture('git status');
  
  // File operations
  final content = Fs.read('pubspec.yaml');
  Fs.write('output.txt', 'Hello');
  Fs.mkdir('build/output');
  
  // Path operations
  final joined = Pth.join('src', 'lib', 'main.dart');
  final ext = Pth.extension('file.dart');  // '.dart'
  
  // Glob matching
  final dartFiles = Glob.find('**/*.dart', 'lib');
  
  // Text processing
  final lines = Text.lines(content);
  final trimmed = Text.trim('  hello  ');
  
  // Environment
  final home = Env.get('HOME');
  
  // YAML parsing
  final yaml = Yaml.load('config.yaml');
  final dumped = Yaml.dump({'key': 'value'});
  
  // Maps utilities
  final merged = Maps.merge(map1, map2);
}
```

### Available Bridges

| Bridge | Classes | Description |
|--------|---------|-------------|
| `AnalyzerBridge` | WorkspaceAnalyzer, ProjectInfo, etc. | Workspace analysis |
| `TomBridge` | CommandRunner, ActionExecutor, etc. | Tom CLI execution |
| `DocScannerBridge` | DocScanner, Document, Section, etc. | Document parsing |
| `DocSpecsBridge` | DocSpecs, SpecDoc, ValidationError, etc. | Schema validation |
| `ScriptingBridge` | Shell, Fs, Pth, Glob, Text, Env, Yaml, Maps | Scripting utilities |

---

## Common Patterns

### One Instance Per Action

```dart
Future<void> executeAction(String actionName) async {
  final context = ActionD4rtContext(
    workspacePath: workspacePath,
    projectName: projectName,
    actionName: actionName,
  );
  
  try {
    await context.executeScript(actionScript);
  } finally {
    context.dispose();  // Always dispose
  }
}
```

### Cumulative Script Setup

D4rt maintains state across calls:

```dart
final d4rt = D4rtInstance.create();

// Step 1: Prepare imports
await d4rt.prepareForScripts();

// Step 2: Define helpers
await d4rt.executeScript('''
  String formatVersion(int major, int minor) => '\$major.\$minor';
  final config = {'debug': true};
  void main() {}
''');

// Step 3: Add more state
await d4rt.executeScript('''
  final data = {'key': 'value'};
  void main() {}
''');

// Step 4: Use everything
final version = await d4rt.evaluate('formatVersion(1, 5)');  // '1.5'
final debug = await d4rt.evaluate('config["debug"]');        // true
final key = await d4rt.evaluate('data["key"]');              // 'value'

d4rt.dispose();
```

### Placeholder-Only Resolution

Skip D4rt for simple substitution:

```dart
// Only resolve ${} and [[]] placeholders
final result = await replacePlaceholders(
  'Value: ${value}, Expr: $D4{calc()}',
  yamlValues: {'value': '42'},
  resolveD4rt: false,  // Skip D4rt
);
// Result: 'Value: 42, Expr: $D4{calc()}'
```

### Context Provider for Flexibility

```dart
// Pluggable and testable
final provider = ActionContextProvider(...);
final instance = D4rtInstance.fromProvider(provider);

// Mock provider in tests
class MockProvider with D4rtContextProviderDefaults {
  @override
  Map<String, dynamic> getContext() => {'test': true};
}
```

---

## Error Handling

### Script Errors

```dart
try {
  await d4rt.executeScript('void main() { throw "Error!"; }');
} catch (e) {
  print('Script error: $e');
}
```

### Disposed Instance

```dart
final d4rt = D4rtInstance.create();
d4rt.dispose();

try {
  await d4rt.evaluate('1 + 1');
} on StateError catch (e) {
  print(e);  // D4rtInstance has been disposed
}
```

### Sync Execution with Future

```dart
try {
  d4rt.executeScriptSync('''
    Future<void> main() async {}
  ''', sourceLocation: 'config.yaml:42');
} on D4rtSyncExecutionException catch (e) {
  print(e.sourceLocation);  // config.yaml:42
  print(e.code);            // The script content
}
```

### Missing Placeholder Values

```dart
// Unresolved placeholders are kept as-is or use default
await resolver.resolve('[{missing.path}]');           // ''
await resolver.resolve('[{missing.path:-default}]');  // 'default'

// YAML placeholders with missing keys
await replacePlaceholders(
  '${missing}',
  yamlValues: {},
);  // '${missing}' (unchanged)
```

---

## Best Practices

### 1. Always Dispose Instances

```dart
final d4rt = D4rtInstance.create();
try {
  await d4rt.executeScript(script);
} finally {
  d4rt.dispose();
}
```

### 2. Use ActionD4rtContext for Actions

```dart
// Good - manages lifecycle
final context = ActionD4rtContext(...);
await context.executeScript(script);
context.dispose();

// Avoid - manual management prone to errors
final d4rt = D4rtInstance.create();
d4rt.setContextAll({...});
await d4rt.executeScript(script);
d4rt.dispose();
```

### 3. Prepare Before Evaluate

```dart
final d4rt = D4rtInstance.create();
await d4rt.prepareForScripts();  // Required for imports
final result = await d4rt.evaluate('Shell.capture("pwd")');
```

### 4. Use Typed main() for Clear Intent

```dart
// Good - explicit return type
final result = await d4rt.executeScript('int main() => 42');

// Less clear
final result = await d4rt.executeScript('main() => 42');
```

### 5. Choose Sync vs Async Appropriately

```dart
// Use sync for configuration, templates (fast, no I/O)
final value = replacePlaceholdersSync(template, yamlValues: config);

// Use async for scripts with I/O, network, or computation
final result = await d4rt.executeScript(buildScript);
```

### 6. Include Source Location in Sync Calls

```dart
// Helps debug when errors occur
d4rt.evaluateSync(
  expression,
  sourceLocation: 'tom_project.yaml:actions.build.pre[0]',
);
```

---

## Related Documentation

- [D4rt Usage Guide](_copilot_guidelines/d4rt/d4rt_usage_guide.md) - Low-level D4rt patterns
- [D4rt BridgedClass Guidelines](_copilot_guidelines/d4rt/d4rt_bridgedclass_guidelines.md) - Creating bridges
- [Scripting Helpers API](doc/api/api_summary_scripting.md) - Shell, Fs, Pth, etc.
