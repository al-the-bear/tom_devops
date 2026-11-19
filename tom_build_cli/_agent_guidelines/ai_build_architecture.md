# Tom AI Build System Architecture

## Overview

The Tom AI Build System is an automated build and documentation tool that leverages GitHub Copilot CLI to perform AI-driven workspace operations. The system uses a metadata-driven architecture where workspace structure is represented as YAML files, prompt templates guide AI interactions, and YAML scripts define automated workflows.

## Core Principles

1. **Metadata-Driven**: All workspace structure is represented in machine-readable metadata (see `project_structure.md`)
2. **Template-Based Prompts**: AI interactions use templates with placeholders filled from metadata
3. **Script-Driven Execution**: Workflows are defined as YAML scripts that orchestrate multiple operations
4. **Incremental Loading**: Large workspaces load metadata incrementally via directory structure
5. **Context Preservation**: Two approaches for maintaining context across CLI invocations

## System Architecture

### 1. Metadata Layer

**Purpose**: Represent workspace structure as machine-readable metadata

**Location**: `.tom_metadata/` directory at workspace root

**Structure**:
```
.tom_metadata/
├── workspace.yaml              # Workspace-level metadata
├── index.yaml                  # Optional quick reference
└── projects/
    ├── {project_name}/
    │   ├── project.yaml        # Project-level metadata
    │   ├── parts/              # Only for multi-part projects
    │   │   └── {part}.yaml
    │   └── modules/            # Module metadata (flat structure)
    │       └── {module}.yaml
```

**Key Features**:
- Directory structure reflects hierarchy (workspace → projects → parts → modules)
- No redundant metadata_path attributes (derivable from directory structure)
- Projects have EITHER parts OR modules section
- All metadata paths relative to appropriate root

**Specification**: See `project_structure.md` for complete schema definitions

**Component**: `MetadataGenerator` - Scans workspace and generates metadata structure

### 2. Prompt Template System

**Purpose**: Define reusable AI prompts with placeholders for metadata injection

**Format**: Markdown files with placeholder syntax

**Template Structure**:
```markdown
# {WORKSPACE_NAME} - {PROJECT_NAME}

## Task
{TASK_DESCRIPTION}

## Project Structure
- Type: {PROJECT_TYPE}
- Parts: {HAS_PARTS}
- Source: {SOURCE_FOLDER}

## Modules in Part: {PART_NAME}
{MODULE_LIST}

## Instructions
{SPECIFIC_INSTRUCTIONS}
```

**Placeholder Types**:
- `{WORKSPACE_NAME}` - From workspace.yaml
- `{PROJECT_NAME}` - From project.yaml
- `{PART_NAME}` - From part.yaml
- `{MODULE_NAME}` - From module.yaml
- `{MODULE_LIST}` - Generated list from metadata
- `{FILE_CONTENT}` - Loaded file content
- Custom placeholders defined per template

**Hierarchical Targeting**:

Prompts can target different levels of the workspace hierarchy:

```yaml
# Target entire workspace
target:
  level: "workspace"
  
# Target specific projects
target:
  level: "project"
  projects: ["core", "client"]
  
# Target specific parts in a project
target:
  level: "part"
  project: "core"
  parts: ["api", "database"]
  
# Target specific modules across multiple parts
target:
  level: "module"
  project: "core"
  parts: ["api", "services"]
  modules: ["auth", "logging"]
  
# Target modules by pattern
target:
  level: "module"
  pattern: "projects/*/parts/*/modules/*_service.yaml"
```

The template engine resolves targets and injects appropriate context for each level.

**Component**: `PromptTemplateEngine` - Loads templates, fills placeholders from metadata

**Specification**: TBD - `prompt_templates.md`

### 3. Script Execution System

**Purpose**: Define and execute multi-step workflows using YAML scripts or Dart scripts

**Formats**: Two approaches for different complexity levels

#### A. Simple YAML Scripts

For straightforward workflows with predefined operations.

**Script Structure**:
```yaml
script:
  name: "Generate Module Documentation"
  description: "Create comprehensive documentation for all modules"
  version: "1.0"

steps:
  - step: "discover_modules"
    action: "load_metadata"
    target: "projects/*/modules/*.yaml"
    
  - step: "generate_prompt"
    action: "fill_template"
    template: "prompts/module_documentation.md"
    context:
      module: "${modules[*]}"
    
  - step: "invoke_copilot"
    action: "run_cli"
    prompt: "${generated_prompt}"
    output: "doc/modules/${module.name}.md"
    
  - step: "accumulate_context"
    action: "append_context"
    files:
      - "${output}"
```

**Operation Types**:
- `load_metadata` - Load metadata from directory pattern
- `fill_template` - Apply prompt template with context
- `run_cli` - Execute Copilot CLI command
- `append_context` - Add to persistent context file
- `validate` - Check output against expectations

#### B. Dart Scripts (via D4art)

For complex workflows requiring arbitrary logic, conditionals, loops, and custom processing.

**Format**: Dart scripts using D4art scripting framework

**Example Dart Script**:
```dart
import 'package:tom_ai_build/tom_ai_build.dart';

void main() async {
  final workspace = await Workspace.load();
  
  // Iterate through all projects
  for (final project in workspace.projects) {
    if (!project.hasParts) {
      // Single-part project - process all modules directly
      await generateDocsForModules(project.modules);
    } else {
      // Multi-part project - iterate through parts
      for (final part in project.parts) {
        print('Processing part: ${part.name}');
        
        // Load all modules in this part
        final modules = await part.loadModules();
        
        // Custom logic: only process modules with more than 3 files
        final complexModules = modules.where((m) => m.files.length > 3);
        
        if (complexModules.isNotEmpty) {
          await generateDocsForModules(complexModules);
        }
      }
    }
  }
}

Future<void> generateDocsForModules(Iterable<Module> modules) async {
  final promptEngine = PromptTemplateEngine();
  final copilot = CopilotCLIAdapter();
  
  for (final module in modules) {
    // Fill template for this module
    final prompt = await promptEngine.fillTemplate(
      'prompts/module_documentation.md',
      context: {'module': module},
    );
    
    // Invoke Copilot CLI
    final output = await copilot.execute(prompt);
    
    // Save output
    await File('doc/modules/${module.name}.md').writeAsString(output);
  }
}
```

**D4art Integration**:
- Full Dart language capabilities (loops, conditionals, async/await)
- Direct access to workspace metadata API
- Custom business logic and transformations
- Integration with external tools and APIs
- Error handling with try-catch
- Reusable functions and libraries

**When to Use Dart Scripts**:
- Complex conditional logic based on metadata
- Custom filtering and aggregation of modules/parts/projects
- Integration with external systems (APIs, databases)
- Custom file processing beyond template filling
- Advanced error recovery strategies
- Performance-critical operations

**When to Use YAML Scripts**:
- Simple linear workflows
- Standard operations (load, template, invoke)
- Quick prototyping
- Non-technical users defining workflows

**Component**: `ScriptExecutor` - Parses YAML scripts and executes steps sequentially

**Component**: `DartScriptRunner` - Executes Dart scripts via D4art framework

**Specification**: TBD - `script_format.md` (YAML), `dart_scripting.md` (Dart/D4art)

### 4. Context Persistence

**Challenge**: Copilot CLI sessions are stateless - each invocation starts fresh

**Solution**: Two approaches (both supported)

#### Approach A: Context File Accumulation
```
context/
├── session_{timestamp}/
│   ├── initial_context.md
│   ├── step_01_output.md
│   ├── step_02_output.md
│   └── accumulated_context.md
```

**Method**:
1. Start with base context (workspace metadata, project structure)
2. Each CLI invocation receives accumulated context via file arguments
3. Append CLI output to accumulated context
4. Next invocation includes all previous context
5. Context grows throughout workflow execution

**Pros**: 
- No external dependencies
- Full control over context
- Context is readable/debuggable

**Cons**: 
- Context size grows linearly
- May hit token limits on long sessions

#### Approach B: Persistent Session State
*(Details TBD - may use local state files, database, or other persistence mechanism)*

**Method**:
1. Maintain session state across invocations
2. Reference previous outputs by ID
3. Load only relevant context per step
4. Prune old context when no longer needed

**Pros**:
- Scalable for long workflows
- Efficient token usage

**Cons**:
- More complex implementation
- Requires state management

**Component**: `ContextManager` - Manages context accumulation and persistence

**Specification**: TBD - `context_management.md`

### 5. CLI Integration

**Purpose**: Interface with GitHub Copilot CLI for AI operations

**Operations**:
- Execute prompts via `gh copilot suggest` or `gh copilot explain`
- Capture CLI output (suggestions, explanations, code)
- Parse structured responses
- Handle errors and retries

**Integration Points**:
- Takes prompts from PromptTemplateEngine
- Receives context from ContextManager
- Returns output to ScriptExecutor
- Logs all interactions for debugging

**Component**: `CopilotCLIAdapter` - Wraps CLI invocations with retry logic and error handling

**Specification**: TBD - `cli_integration.md`

### 6. VS Code Scripting Integration

**Purpose**: Execute workflows directly within VS Code using its scripting API

**Approach**: Use VS Code's scripting capabilities combined with D4art for Dart-based automation

**Architecture**:
```
VS Code Extension API
    ↓
D4art Scripting Runtime
    ↓
Tom AI Build Library (Dart)
    ↓
Workspace Metadata + Copilot CLI
```

**Benefits**:
- Direct integration with VS Code editor
- Access to VS Code APIs (editor, workspace, tasks)
- Real-time feedback in editor UI
- Seamless debugging experience
- No separate process management

**VS Code Integration Points**:

1. **Editor Integration**:
   - Read/write files directly via VS Code API
   - Navigate to specific lines in generated code
   - Show inline errors and suggestions
   - Update editor decorations with AI progress

2. **Task Integration**:
   - Register as VS Code tasks
   - Run from command palette
   - Integration with existing build tasks
   - Terminal output with clickable links

3. **UI Integration**:
   - Progress notifications
   - Input boxes for parameters
   - Quick picks for module/part selection
   - Tree view for workflow execution status

**Example VS Code + D4art Script**:
```dart
import 'package:tom_ai_build/tom_ai_build.dart';
import 'package:d4art/d4art.dart';

void main() async {
  // Access VS Code API through D4art
  final vscode = VSCode.instance;
  
  // Get workspace root from VS Code
  final workspaceRoot = vscode.workspace.rootPath;
  final workspace = await Workspace.load(workspaceRoot);
  
  // Show quick pick for project selection
  final selectedProject = await vscode.window.showQuickPick(
    workspace.projects.map((p) => p.name).toList(),
    placeHolder: 'Select a project to document',
  );
  
  if (selectedProject == null) return;
  
  final project = workspace.projectByName(selectedProject);
  
  // Show progress notification
  await vscode.window.withProgress(
    location: ProgressLocation.notification,
    title: 'Generating documentation for $selectedProject',
    (progress) async {
      if (project.hasParts) {
        // Multi-part project
        for (final part in project.parts) {
          progress.report(message: 'Processing part: ${part.name}');
          
          final modules = await part.loadModules();
          for (final module in modules) {
            await generateModuleDocs(module);
            progress.report(increment: 100 / modules.length);
          }
        }
      } else {
        // Single-part project
        final modules = await project.loadModules();
        for (final module in modules) {
          await generateModuleDocs(module);
          progress.report(increment: 100 / modules.length);
        }
      }
    },
  );
  
  // Show completion message with action
  final action = await vscode.window.showInformationMessage(
    'Documentation generated successfully',
    'Open Docs Folder',
  );
  
  if (action == 'Open Docs Folder') {
    await vscode.commands.execute('revealInExplorer', 'doc/');
  }
}
```

**Execution Models**:

1. **Command Palette**: Register commands that appear in VS Code command palette
2. **Context Menu**: Right-click on folders/files to trigger workflows
3. **Keybindings**: Assign keyboard shortcuts to common workflows
4. **Status Bar**: Show status and allow quick access to workflows
5. **Codelens**: Inline actions in editor for specific code sections

**Configuration via VS Code Settings**:
```json
{
  "tomAiBuild.contextApproach": "accumulation",
  "tomAiBuild.maxContextSize": 50000,
  "tomAiBuild.autoRunOnSave": false,
  "tomAiBuild.defaultWorkflows": [
    "scripts/generate_docs.dart",
    "scripts/validate_structure.dart"
  ]
}
```

**Component**: `VSCodeScriptAdapter` - Integrates D4art scripts with VS Code API

**Specification**: TBD - `vscode_integration.md`

### 7. Orchestration

**Purpose**: Coordinate all components to execute complete workflows

**Responsibilities**:
1. Initialize workspace (validate structure, load metadata)
2. Load and parse script files
3. Execute script steps in sequence
4. Coordinate between components:
   - MetadataGenerator → PromptTemplateEngine (provide context)
   - PromptTemplateEngine → CopilotCLIAdapter (provide prompts)
   - CopilotCLIAdapter → ContextManager (accumulate outputs)
   - ContextManager → CopilotCLIAdapter (provide context for next invocation)
5. Handle errors and rollback if needed
6. Generate execution reports

**Component**: `WorkflowOrchestrator` - Main entry point, coordinates all operations

**Entry Point**: `bin/tom_ai_build.dart` - CLI interface for running workflows

## Execution Flow

### Typical Workflow Execution

**YAML Script Execution**:
```
1. User invokes: tom_ai_build run script.yaml

2. WorkflowOrchestrator:
   ├─ Validate workspace structure
   ├─ Initialize ContextManager (create session)
   └─ Load script.yaml

3. For each script step:
   ├─ ScriptExecutor parses step definition
   │
   ├─ If load_metadata:
   │   └─ MetadataGenerator loads specified metadata
   │
   ├─ If fill_template:
   │   ├─ PromptTemplateEngine loads template
   │   ├─ Injects metadata + context
   │   └─ Returns filled prompt
   │
   ├─ If run_cli:
   │   ├─ ContextManager provides accumulated context
   │   ├─ CopilotCLIAdapter executes CLI command
   │   └─ Returns CLI output
   │
   ├─ If append_context:
   │   └─ ContextManager adds output to context file
   │
   └─ Continue to next step

4. Finalize:
   ├─ Generate execution report
   ├─ Save final context
   └─ Exit with status
```

**Dart Script Execution (via D4art)**:
```
1. User invokes: tom_ai_build run script.dart
   OR: VS Code Command Palette → "Tom AI Build: Run Script"

2. DartScriptRunner:
   ├─ Load workspace metadata
   ├─ Initialize D4art runtime
   └─ Execute Dart script with workspace context

3. Script execution:
   ├─ Direct API access to Workspace/Project/Part/Module
   ├─ Custom logic (loops, conditions, filtering)
   ├─ Call PromptTemplateEngine.fillTemplate() as needed
   ├─ Call CopilotCLIAdapter.execute() as needed
   ├─ Call ContextManager.append() as needed
   └─ Custom file I/O, external API calls, etc.

4. VS Code Integration (if running in VS Code):
   ├─ VSCodeScriptAdapter provides VS Code API access
   ├─ Update UI (progress, notifications)
   ├─ Navigate editor to results
   └─ Register completion handlers

5. Finalize:
   ├─ Script completes with exit code
   ├─ Generate execution report
   └─ Clean up resources
```

## Component Dependencies

**CLI Execution Mode**:
```
WorkflowOrchestrator
├── ScriptExecutor (YAML)
│   ├── MetadataGenerator
│   ├── PromptTemplateEngine
│   │   └── MetadataGenerator (for context)
│   ├── CopilotCLIAdapter
│   │   └── ContextManager (for context)
│   └── ContextManager
└── Logger/Reporter
```

**D4art Execution Mode**:
```
DartScriptRunner
├── D4art Runtime
├── Tom AI Build Library
│   ├── Workspace API (load/query metadata)
│   ├── PromptTemplateEngine
│   ├── CopilotCLIAdapter
│   └── ContextManager
└── VSCodeScriptAdapter (optional)
    └── VS Code Extension API
```

## Extensibility

### Adding New Components

Each component is defined by an interface:

- `IMetadataGenerator` - Generates/loads metadata
- `IPromptTemplateEngine` - Processes templates
- `IScriptExecutor` - Executes workflow steps
- `IContextManager` - Manages context persistence
- `ICopilotCLIAdapter` - Interfaces with CLI
- `IWorkflowOrchestrator` - Coordinates execution
- `IDartScriptRunner` - Executes Dart scripts via D4art
- `IVSCodeScriptAdapter` - Integrates with VS Code API

New implementations can be added without affecting other components.

### Adding New Script Operations

Script operations are registered in `ScriptExecutor`:

```dart
scriptExecutor.registerOperation('custom_operation', (params) {
  // Implementation
});
```

### Adding New Template Functions

Template functions can extend placeholder capabilities:

```dart
templateEngine.registerFunction('format_list', (items) {
  return items.map((i) => '- $i').join('\n');
});
```

Usage in template: `{FORMAT_LIST(modules)}`

## Configuration

### Workspace Configuration

Optional workspace-level configuration in `.tom_metadata/config.yaml`:

```yaml
ai_build_config:
  context_approach: "accumulation"  # accumulation | persistent
  max_context_size: 50000           # tokens
  cli_retry_attempts: 3
  log_level: "info"                 # debug | info | warning | error
  output_dir: "ai_build_output"
```

## Error Handling

### Error Types

1. **Validation Errors**: Invalid metadata structure, missing required files
2. **Execution Errors**: CLI failures, script syntax errors
3. **Context Errors**: Context size exceeded, context file corruption
4. **Integration Errors**: CLI not available, network issues

### Recovery Strategies

- **Retry**: CLI invocations with exponential backoff
- **Fallback**: Use alternative context approach if primary fails
- **Checkpoint**: Save state at each script step for resume
- **Rollback**: Undo changes if critical error occurs

## Implementation Phases

### Phase 1: Foundation (Current)
- ✅ Project structure design (`project_structure.md`)
- ✅ Architecture design (`ai_build_architecture.md`)
- ⏳ Metadata generator implementation
- ⏳ Basic workspace validation

### Phase 2: Core Components
- Prompt template engine
- Script executor (basic operations)
- Context manager (accumulation approach)
- CLI adapter (basic invocation)

### Phase 3: Integration
- Workflow orchestrator
- End-to-end testing
- Error handling and logging
- Documentation generation scripts

### Phase 4: Advanced Features
- Persistent session state (alternative to accumulation)
- Custom operations and template functions
- Performance optimization
- Web UI for monitoring

## Specification Documents

Each major component has a detailed specification:

1. **project_structure.md** (✅ Complete) - Metadata schema and directory structure
2. **prompt_templates.md** (⏳ TODO) - Template syntax, placeholder definitions, and hierarchical targeting
3. **script_format.md** (⏳ TODO) - YAML script schema and operation types
4. **dart_scripting.md** (⏳ TODO) - D4art integration and Dart script API reference
5. **context_management.md** (⏳ TODO) - Context persistence strategies (accumulation and persistent state)
6. **cli_integration.md** (⏳ TODO) - CLI adapter implementation details
7. **vscode_integration.md** (⏳ TODO) - VS Code scripting API and D4art integration

## Related Documents

- `project_structure.md` - Detailed metadata schemas
- `README.md` - User-facing documentation and quick start
- `CONTRIBUTING.md` - Development guidelines (TBD)

## Future Considerations

- Support for other AI CLI tools (not just GitHub Copilot)
- Distributed execution for large workspaces
- Integration with CI/CD pipelines
- Real-time monitoring dashboard
- Template marketplace/sharing
