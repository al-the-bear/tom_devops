# Bridging VS Code Extensions with Dart Code

## Overview

This document focuses on bridging VS Code extensions (written in TypeScript) with Dart code execution using D4rt. While VS Code extensions must be written in TypeScript/JavaScript, we can execute Dart code dynamically and provide bidirectional communication between the extension and Dart scripts.

## Architecture

```
VS Code Extension (TypeScript)
    ↓
Bridge API (TypeScript functions)
    ↓
D4rt Interpreter (JavaScript/WASM)
    ↓
Dart Scripts (tom_ai_build library)
    ↓
Native Dart APIs & Workspace Operations
```

**Key Concept**: The extension provides a "bridge" - a set of TypeScript functions that are exposed to Dart code running in D4rt, and vice versa.

## Bridging Fundamentals

### The Bridge Pattern

The bridge allows:
1. **TypeScript → Dart**: VS Code extension calls Dart functions
2. **Dart → TypeScript**: Dart code calls VS Code APIs

### Setup Requirements

**package.json dependencies**:
```json
{
  "dependencies": {
    "d4rt": "^0.1.9"
  },
  "devDependencies": {
    "@types/vscode": "^1.85.0",
    "@types/node": "^18.x",
    "typescript": "^5.3.0"
  }
}
```

Install D4rt:
```bash
npm install d4rt
```

## Core VS Code APIs

### Importing VS Code API

```typescript
import * as vscode from 'vscode';
```

All VS Code APIs are available through the `vscode` namespace.

**Documentation**: https://code.visualstudio.com/api/references/vscode-api

## Common VS Code Operations

### 1. Workspace Operations

#### Get Workspace Root

```typescript
import * as vscode from 'vscode';

function getWorkspaceRoot(): string | undefined {
  const workspaceFolders = vscode.workspace.workspaceFolders;
  if (!workspaceFolders || workspaceFolders.length === 0) {
    return undefined;
  }
  return workspaceFolders[0].uri.fsPath;
}
```

#### Read File

```typescript
async function readFile(filePath: string): Promise<string> {
  const uri = vscode.Uri.file(filePath);
  const content = await vscode.workspace.fs.readFile(uri);
  return Buffer.from(content).toString('utf8');
}
```

#### Write File

```typescript
async function writeFile(filePath: string, content: string): Promise<void> {
  const uri = vscode.Uri.file(filePath);
  const buffer = Buffer.from(content, 'utf8');
  await vscode.workspace.fs.writeFile(uri, buffer);
}
```

#### Create Directory

```typescript
async function createDirectory(dirPath: string): Promise<void> {
  cBridge Implementation

### Step 1: Import Dependencies

```typescript
import * as vscode from 'vscode';
import { D4rt } from 'd4rt';
import * as fs from 'fs';
import * as path from 'path';
```

### Step 2: Create VS Code API Bridge> type === vscode.FileType.File)
    .map(([name]) => name);
}
```

**Documentation**: https://code.visualstudio.com/api/references/vscode-api#workspace

### Step 3: Create Bridged Class for D4rt

To expose the bridge to Dart code, create a `BridgedClass`:

```typescript
import { BridgedClass } from 'd4rt';

function createVSCodeBridgeDefinition(bridge: VSCodeBridge) {
  return new BridgedClass({
    nativeType: VSCodeBridge,
    name: 'VSCode',
    
    // Constructor
    constructors: {
      '': () => bridge, // Return singleton instance
    },
    
    // Methods
    methods: {
      'getWorkspaceRoot': (visitor, target, positional, named) => {
        return bridge.getWorkspaceRoot();
      },
      
      'readFile': async (visitor, target, positional, named) => {
        const [filePath] = positional as [string];
        return await bridge.readFile(filePath);
      },
      
      'writeFile': async (visitor, target, positional, named) => {
        const [filePath, content] = positional as [string, string];
        return await bridge.writeFile(filePath, content);
      },
      
      'showInfo': (visitor, target, positional, named) => {
        const [message] = positional as [string];
        bridge.showInfo(message);
      },
      
      'showError': (visitor, target, positional, named) => {
        const [message] = positional as [string];
        bridge.showError(message);
      },
      
      'openFile': async (visitor, target, positional, named) => {
        const [filePath] = positional as [string];
        return await bridge.openFile(filePath);
      },
      
      'navigateToLine': async (visitor, target, positional, named) => {
        const [filePath, line] = positional as [string, number];
        return await bridge.navigateToLine(filePath, line);
      },
      
      'askCopilot': async (visitor, target, positional, named) => {
        const [prompt] = positional as [string];
        return await bridge.askCopilot(prompt);
      },
    },
  });
}
```

### 3. UI Operations

#### Show Information Message

```typescript
async function showInfo(message: string): Promise<void> {
  await vscode.window.showInformationMessage(message);
}
```

#### Show Information Message with Actions

```typescript
async function showInfoWithActions(
  message: string, 
  ...actions: string[]
): Promise<string | undefined> {
  return await vscode.window.showInformationMessage(message, ...actions);
}

// Usage:
const choice = await showInfoWithActions(
  'Documentation generated',
  'Open Docs',
  'Close'
);

if (choice === 'Open Docs') {
  // Handle action
}
```

#### Show Error Message

```typescript
async function showError(message: string): Promise<void> {
  await vscode.window.showErrorMessage(message);
}
```

#### Show Progress Notification

```typescript
async function showProgress<T>(
  title: string,
  task: (progress: vscode.Progress<{ message?: string; increment?: number }>) => Promise<T>
): Promise<T> {
  return await vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Notification,
      title: title,
      cancellable: false
    },
    task
  );
}

// Usage:
await showProgress('Generating documentation', async (progress) => {
  progress.report({ message: 'Processing modules...', increment: 0 });
  // Do work
  progress.report({ message: 'Writing files...', increment: 50 });
  // More work
  progress.report({ increment: 100 });
});
```

#### Show Quick Pick (Selection Menu)

```typescript
async function showQuickPick(
  items: string[], 
  placeholder: string
): Promise<string | undefined> {
  return await vscode.window.showQuickPick(items, {
    placeHolder: placeholder,
    canPickMany: false
  });
}

// Multi-select:
async function showMultiQuickPick(
  items: string[], 
  placeholder: string
): Promise<string[] | undefined> {
  return await vscode.window.showQuickPick(items, {
    placeHolder: placeholder,
    canPickMany: true
  });
}
```

#### Show Input Box

```typescript
async function showInputBox(
  prompt: string,
  defaultValue?: string
): Promise<string | undefined> {
  return await vscode.window.showInputBox({
    prompt: prompt,
    value: defaultValue,
    placeHolder: 'Enter value...'
  });
}
```

### Step 4: Execute Dart Script with Bridge

Now use D4rt to execute Dart code with the bridge:

```typescript
async function executeDartScriptWithBridge(
  scriptPath: string,
  context: vscode.ExtensionContext
): Promise<any> {
  try {
    // Read Dart script
    const scriptContent = fs.readFileSync(scriptPath, 'utf8');
    
    // Create bridge instance
    const bridge = new VSCodeBridge(context);
    
    // Create D4rt interpreter
    const interpreter = new D4rt();
    
    // Register the bridge
    const bridgeDefinition = createVSCodeBridgeDefinition(bridge);
    interpreter.registerBridgedClass(
      bridgeDefinition,
      'package:vscode/vscode.dart'
    );
    
    // Grant necessary permissions
    interpreter.grant({ type: 'filesystem', mode: 'read' });
    
    // Execute script
    const result = await interpreter.execute({
      source: scriptContent,
      name: 'main'
    });
    
    return result;
  } catch (error) {
    vscode.window.showErrorMessage(`Script execution failed: ${error}`);
    throw error;
  }
}
```

### Step 5: Use Bridge from Dart

Now Dart scripts can use the VS Code API:

```dart
import 'package:vscode/vscode.dart';

void main() async {
  // Create VSCode instance
  final vscode = VSCode();
  
  // Get workspace root
  final workspaceRoot = vscode.getWorkspaceRoot();
  print('Workspace: $workspaceRoot');
  
  // Read a file
  final content = await vscode.readFile('$workspaceRoot/README.md');
  
  // Show info to user
  vscode.showInfo('File read successfully!');
  
  // Ask Copilot
  final response = await vscode.askCopilot(
    'Explain this code: $content'
  );
  
  // Write result to file
  await vscode.writeFile(
    '$workspaceRoot/doc/analysis.md',
    response
  );
  
  // Open the file
  await vscode.openFile('$workspaceRoot/doc/analysis.md');
}
```

## Calling Regular Dart Code (Outside D4rt)

### Option 1: Execute Dart CLI Tool

For compiled Dart code, use VS Code's terminal API:

```typescript
async function runDartCLI(args: string[]): Promise<string> {
  return new Promise((resolve, reject) => {
    const { exec } = require('child_process');
    const command = `dart ${args.join(' ')}`;
    
    exec(command, (error: any, stdout: string, stderr: string) => {
      if (error) {
        reject(error);
      } else {
        resolve(stdout);
      }
    });
  });
}

// Usage:
const output = await runDartCLI(['run', 'tom_ai_build', 'generate-docs']);
```

### Option 2: Execute Dart Task

```typescript
async function runDartTask(command: string, args: string[]): Promise<void> {
  const execution = new vscode.ShellExecution('dart', [command, ...args]);
  const task = new vscode.Task(
    { type: 'dart', task: command },
    vscode.TaskScope.Workspace,
    `Dart: ${command}`,
    'dart',
    execution
  );
  
  await vscode.tasks.executeTask(task);
}

// Usage:
await runDartTask('run', ['tom_ai_build', 'generate-docs']);
```

### Option 3: Dart Process with IPC

For bidirectional communication with a Dart process:

```typescript
import { spawn } from 'child_process';

class DartProcess {
  private process: any;
  
  start(scriptPath: string) {
    this.process = spawn('dart', ['run', scriptPath], {
      stdio: ['pipe', 'pipe', 'pipe', 'ipc']
    });
    
    this.process.on('message', (message: any) => {
      console.log('From Dart:', message);
      // Handle messages from Dart
    });
  }
  
  send(message: any) {
    this.process.send(message);
  }
  
  stop() {
    this.process.kill();
  }
}

// Usage:
const dartProcess = new DartProcess();
dartProcess.start('/path/to/script.dart');
dartProcess.send({ command: 'generate-docs', project: 'core' });
```

## Complete Example: Generate Docs Command

### TypeScript Extension Code

```typescript
export function activate(context: vscode.ExtensionContext) {
  const command = vscode.commands.registerCommand(
    'tomAiBuild.generateDocsViaDart',
    async () => {
      await generateDocsWithDartBridge(context);
    }
  );
  
  context.subscriptions.push(command);
}

async function generateDocsWithDartBridge(
  context: vscode.ExtensionContext
): Promise<void> {
  const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!workspaceRoot) {
    vscode.window.showErrorMessage('No workspace open');
    return;
  }
  
  await vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Notification,
      title: 'Generating Documentation',
      cancellable: false
    },
    async (progress) => {
      progress.report({ message: 'Loading script...', increment: 10 });
      
      // Script path
      const scriptPath = path.join(
        workspaceRoot,
        'scripts',
        'generate_docs.dart'
      );
      
      progress.report({ message: 'Executing Dart script...', increment: 30 });
      
      // Execute with bridge
      await executeDartScriptWithBridge(scriptPath, context);
      
      progress.report({ message: 'Complete!', increment: 100 });
    }
  );
  
  vscode.window.showInformationMessage('Documentation generated!');
}
```

### Dart Script (scripts/generate_docs.dart)

```dart
import 'package:vscode/vscode.dart';

void main() async {
  final vscode = VSCode();
  
  // Get workspace
  final workspaceRoot = vscode.getWorkspaceRoot();
  if (workspaceRoot == null) {
    vscode.showError('No workspace root');
    return;
  }
  
  vscode.showInfo('Starting documentation generation...');
  
  // Read metadata
  final metadataPath = '$workspaceRoot/.tom_metadata/workspace.yaml';
  final metadata = await vscode.readFile(metadataPath);
  
  // Parse projects (simplified)
  final projects = ['core', 'client', 'server'];
  
  for (final project in projects) {
    vscode.showInfo('Processing project: $project');
    
    // Ask Copilot to generate docs
    final prompt = '''
Generate documentation for project: $project

Provide an overview, key features, and usage examples.
''';
    
    final docs = await vscode.askCopilot(prompt);
    
    // Write to file
    final outputPath = '$workspaceRoot/doc/$project.md';
    await vscode.writeFile(outputPath, docs);
  }
  
  vscode.showInfo('Documentation generation complete!');
}
```

## Passing Data Between TypeScript and Dart

### TypeScript → Dart (Parameters)

Pass data via script context:

```typescript
const interpreter = new D4rt();

// Pass parameters
const result = await interpreter.execute({
  source: scriptContent,
  name: 'processData',
  positionalArgs: ['project_name', 42],
  namedArgs: { verbose: true }
});
```

Dart receives parameters:

```dart
void processData(String projectName, int count, {bool verbose = false}) {
  print('Project: $projectName, Count: $count, Verbose: $verbose');
}
```

### Dart → TypeScript (Return Values)

Dart returns data:

```dart
Map<String, dynamic> generateReport() {
  return {
    'projects': ['core', 'client'],
    'moduleCount': 42,
    'timestamp': DateTime.now().toIso8601String(),
  };
}
```

TypeScript receives:

```typescript
const result = await interpreter.execute({
  source: scriptContent,
  name: 'generateReport'
});

console.log('Projects:', result.projects);
console.log('Module count:', result.moduleCount);
```

### Callbacks (Dart → TypeScript → Dart)

For progress updates:

```typescript
const progressCallback = (message: string, percent: number) => {
  progress.report({ message, increment: percent });
};

// Pass callback to Dart
const bridgeWithCallback = new BridgedClass({
  // ... bridge definition
  methods: {
    'reportProgress': (visitor, target, positional, named) => {
      const [message, percent] = positional as [string, number];
      progressCallback(message, percent);
    }
  }
});
```

Dart calls back:

```dart
void longRunningTask(VSCode vscode) {
  vscode.reportProgress('Step 1...', 25);
  // Do work
  vscode.reportProgress('Step 2...', 50);
  // More work
  vscode.reportProgress('Complete!', 100);
}
```

## Best Practices

1. **Bridge Design**:
   - Keep bridge methods simple and focused
   - Use async/await for operations that may take time
   - Handle errors gracefully on both sides

2. **D4rt Permissions**:
   - Grant minimal permissions needed
   - Use specific file paths rather than blanket access
   - Document security requirements

3. **Error Handling**:
   - Catch errors in both TypeScript and Dart
   - Show user-friendly error messages via VS Code UI
   - Log detailed errors for debugging

4. **Performance**:
   - Minimize bridge crossings (group operations)
   - Cache results when appropriate
   - Use progress reporting for long operations

5. **Type Safety**:
   - Validate types when crossing bridge
   - Use TypeScript strict mode
   - Handle null/undefined carefully

6. **Testing**:
   - Test bridge methods independently
   - Test Dart scripts with mock bridge
   - Integration test in VS Code Extension Host

## Documentation References

### VS Code Extension API
- **Main API**: https://code.visualstudio.com/api/references/vscode-api
- **Extension Guides**: https://code.visualstudio.com/api/extension-guides/overview
- **Language Model API**: https://code.visualstudio.com/api/extension-guides/language-model

### D4rt
- **Package**: https://pub.dev/packages/d4rt
- **Repository**: https://github.com/kodjodevf/d4rt
- **Bridging Guide**: https://github.com/kodjodevf/d4rt/blob/main/BRIDGING_GUIDE.md
- **Tom AI Build D4rt Guide**: See `ai_build_guidelines/d4rt.md`

### Extension Setup
- **Complete Setup Guide**: See `tom_vscode_extension/tom_ai_build_vscode_integration.md`
- **Example Extension**: See `tom_vscode_extension/src/extension.ts`

## Summary

This document focused on:
- Creating a bridge between TypeScript (VS Code) and Dart (D4rt)
- Exposing VS Code APIs to Dart scripts
- Executing Dart code from VS Code extensions
- Calling regular Dart CLI tools
- Passing data bidirectionally
- Complete working examples

For installation and setup instructions, see [tom_ai_build_vscode_integration.md](../../tom_vscode_extension/tom_ai_build_vscode_integration.md).


### Using Language Model API

VS Code provides the Language Model API (`vscode.lm`) to interact with GitHub Copilot and other language models.

#### Check Model Availability

```typescript
async function getCopilotModel(): Promise<vscode.LanguageModelChat | undefined> {
  const models = await vscode.lm.selectChatModels({
    vendor: 'copilot',
    family: 'gpt-4o'
  });
  
  if (models.length === 0) {
    vscode.window.showErrorMessage('No Copilot models available');
    return undefined;
  }
  
  return models[0];
}
```

#### Send Request to Copilot

```typescript
async function askCopilot(prompt: string): Promise<string> {
  try {
    const model = await getCopilotModel();
    if (!model) {
      throw new Error('Copilot model not available');
    }
    
    // Create chat messages
    const messages = [
      vscode.LanguageModelChatMessage.User(prompt)
    ];
    
    // Send request
    const response = await model.sendRequest(messages, {}, new vscode.CancellationTokenSource().token);
    
    // Collect response
    let fullResponse = '';
    for await (const chunk of response.text) {
      fullResponse += chunk;
    }
    
    return fullResponse;
  } catch (err) {
    if (err instanceof vscode.LanguageModelError) {
      console.log('Language model error:', err.message, err.code);
      throw new Error(`Copilot error: ${err.message}`);
    }
    throw err;
  }
}
```

#### Using Copilot in Extension

```typescript
async function generateDocumentationWithCopilot(
  moduleName: string,
  moduleCode: string
): Promise<string> {
  const prompt = `
Generate comprehensive documentation for the following Dart module:

Module Name: ${moduleName}

Code:
\`\`\`dart
${moduleCode}
\`\`\`

Please include:
1. Overview
2. Classes and methods
3. Usage examples
4. API reference
`;

  const documentation = await askCopilot(prompt);
  return documentation;
}
```

#### Register Chat Participant (Advanced)

For custom chat experiences in the Copilot Chat panel:

```typescript
export function activate(context: vscode.ExtensionContext) {
  // Note: Chat participants require special API proposal
  // Check VS Code version and API availability
  
  const participant = vscode.chat.createChatParticipant(
    'tom-ai-build',
    async (request, context, stream, token) => {
      // Handle chat requests
      if (request.command === 'generate-docs') {
        stream.markdown('Generating documentation...\n');
        
        const docs = await generateDocumentation();
        stream.markdown(`Documentation generated: ${docs}`);
      }
    }
  );
  
  participant.iconPath = vscode.Uri.file(
    context.asAbsolutePath('resources/icon.png')
  );
  
  context.subscriptions.push(participant);
}
```

**Documentation**: 
- Language Model API: https://code.visualstudio.com/api/extension-guides/language-model
- Chat API: https://code.visualstudio.com/api/extension-guides/chat

## Integrating D4rt with VS Code Extension

### Extension Entry Point

**src/extension.ts**:
```typescript
import * as vscode from 'vscode';
import * as path from 'path';
import { D4rt } from 'd4rt';

export function activate(context: vscode.ExtensionContext) {
  console.log('Tom AI Build extension is now active');
  
  // Register commands
  registerCommands(context);
}

export function deactivate() {
  // Cleanup
}

function registerCommands(context: vscode.ExtensionContext) {
  // Run Dart script command
  const runScriptCmd = vscode.commands.registerCommand(
    'tomAiBuild.runScript',
    async (uri: vscode.Uri) => {
      await runDartScript(uri.fsPath);
    }
  );
  
  // Generate documentation command
  const generateDocsCmd = vscode.commands.registerCommand(
    'tomAiBuild.generateDocs',
    async () => {
      await generateDocsWithProgress();
    }
  );
  
  context.subscriptions.push(runScriptCmd, generateDocsCmd);
}
```

### Execute Dart Script via D4rt

```typescript
import { D4rt } from 'd4rt';
import * as fs from 'fs';

async function runDartScript(scriptPath: string): Promise<any> {
  try {
    // Read script
    const scriptContent = fs.readFileSync(scriptPath, 'utf8');
    
    // Create interpreter
    const interpreter = new D4rt();
    
    // Grant necessary permissions
    interpreter.grant({ type: 'filesystem', mode: 'read' });
    
    // Get workspace root from VS Code
    const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    
    // Execute script with workspace context
    const result = await interpreter.execute({
      source: scriptContent,
      // Pass VS Code APIs as bridges
      context: {
        workspaceRoot,
        vscode: createVSCodeBridge()
      }
    });
    
    return result;
  } catch (error) {
    vscode.window.showErrorMessage(`Script execution failed: ${error}`);
    throw error;
  }
}
```

### Bridge VS Code APIs to Dart

```typescript
function createVSCodeBridge() {
  return {
    // Expose VS Code operations to Dart scripts
    showMessage: (message: string) => {
      vscode.window.showInformationMessage(message);
    },
    
    readFile: async (filePath: string) => {
      const uri = vscode.Uri.file(filePath);
      const content = await vscode.workspace.fs.readFile(uri);
      return Buffer.from(content).toString('utf8');
    },
    
    writeFile: async (filePath: string, content: string) => {
      const uri = vscode.Uri.file(filePath);
      await vscode.workspace.fs.writeFile(
        uri,
        Buffer.from(content, 'utf8')
      );
    },
    
    openFile: async (filePath: string) => {
      const uri = vscode.Uri.file(filePath);
      const doc = await vscode.workspace.openTextDocument(uri);
      await vscode.window.showTextDocument(doc);
    },
    
    askCopilot: async (prompt: string) => {
      return await askCopilot(prompt);
    }
  };
}
```

### Complete Example: Generate Docs with Progress

```typescript
async function generateDocsWithProgress(): Promise<void> {
  const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!workspaceRoot) {
    vscode.window.showErrorMessage('No workspace folder open');
    return;
  }
  
  await vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Notification,
      title: 'Generating Documentation',
      cancellable: true
    },
    async (progress, token) => {
      // Check for cancellation
      if (token.isCancellationRequested) {
        return;
      }
      
      progress.report({ message: 'Loading workspace metadata...', increment: 10 });
      
      // Load and execute Dart script
      const scriptPath = path.join(workspaceRoot, 'scripts', 'generate_docs.dart');
      const scriptContent = fs.readFileSync(scriptPath, 'utf8');
      
      const interpreter = new D4rt();
      interpreter.grant({ type: 'filesystem', mode: 'any' });
      
      progress.report({ message: 'Analyzing modules...', increment: 30 });
      
      // Execute with progress callback
      const result = await interpreter.execute({
        source: scriptContent,
        context: {
          workspaceRoot,
          reportProgress: (msg: string, inc: number) => {
            progress.report({ message: msg, increment: inc });
          },
          askCopilot: async (prompt: string) => {
            return await askCopilot(prompt);
          }
        }
      });
      
      progress.report({ message: 'Complete!', increment: 100 });
      
      // Show result
      const action = await vscode.window.showInformationMessage(
        'Documentation generated successfully',
        'Open Docs Folder'
      );
      
      if (action === 'Open Docs Folder') {
        const docsUri = vscode.Uri.file(path.join(workspaceRoot, 'docs'));
        await vscode.commands.executeCommand('revealInExplorer', docsUri);
      }
    }
  );
}
```

## Testing Extensions

### Launch Configuration

**.vscode/launch.json**:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Run Extension",
      "type": "extensionHost",
      "request": "launch",
      "args": [
        "--extensionDevelopmentPath=${workspaceFolder}"
      ],
      "outFiles": [
        "${workspaceFolder}/out/**/*.js"
      ],
      "preLaunchTask": "${defaultBuildTask}"
    }
  ]
}
```

Press F5 to launch a new VS Code window with the extension loaded.

## Configuration

### Extension Settings

Add settings in `package.json`:

```json
{
  "contributes": {
    "configuration": {
      "title": "Tom AI Build",
      "properties": {
        "tomAiBuild.contextApproach": {
          "type": "string",
          "default": "accumulation",
          "enum": ["accumulation", "persistent"],
          "description": "Context persistence approach"
        },
        "tomAiBuild.maxContextSize": {
          "type": "number",
          "default": 50000,
          "description": "Maximum context size in tokens"
        },
        "tomAiBuild.autoRunOnSave": {
          "type": "boolean",
          "default": false,
          "description": "Automatically run scripts on save"
        }
      }
    }
  }
}
```

### Read Settings in Code

```typescript
function getConfiguration() {
  const config = vscode.workspace.getConfiguration('tomAiBuild');
  
  return {
    contextApproach: config.get<string>('contextApproach'),
    maxContextSize: config.get<number>('maxContextSize'),
    autoRunOnSave: config.get<boolean>('autoRunOnSave')
  };
}
```

## Documentation References

### Official VS Code Documentation

1. **Extension API**: https://code.visualstudio.com/api
2. **API Reference**: https://code.visualstudio.com/api/references/vscode-api
3. **Extension Guides**: https://code.visualstudio.com/api/extension-guides/overview
4. **Language Model API**: https://code.visualstudio.com/api/extension-guides/language-model
5. **Chat API**: https://code.visualstudio.com/api/extension-guides/chat
6. **Extension Samples**: https://github.com/microsoft/vscode-extension-samples
7. **Publishing Extensions**: https://code.visualstudio.com/api/working-with-extensions/publishing-extension

### Key API Namespaces

- `vscode.workspace` - Workspace operations (files, folders, settings)
- `vscode.window` - UI operations (messages, input, editors, terminals)
- `vscode.commands` - Command registration and execution
- `vscode.tasks` - Task creation and execution
- `vscode.lm` - Language model integration (Copilot)
- `vscode.chat` - Chat participant API
- `vscode.languages` - Language features (diagnostics, completions)
- `vscode.debug` - Debugging API

### TypeScript Definitions

Install type definitions:
```bash
npm install --save-dev @types/vscode
```

Import in TypeScript:
```typescript
import * as vscode from 'vscode';
```

### D4rt Integration

- **D4rt Package**: https://pub.dev/packages/d4rt
- **D4rt Repository**: https://github.com/kodjodevf/d4rt
- **D4rt Documentation**: https://pub.dev/documentation/d4rt/latest/

## Best Practices

1. **Error Handling**: Always wrap operations in try-catch blocks
2. **Async Operations**: Use async/await for all asynchronous operations
3. **Dispose Resources**: Add disposables to `context.subscriptions`
4. **Progress Feedback**: Show progress for long-running operations
5. **Cancellation**: Support cancellation tokens where appropriate
6. **Settings**: Make behavior configurable through settings
7. **Logging**: Use output channels for debugging
8. **Security**: Validate input and restrict D4rt permissions appropriately
9. **Performance**: Don't block the UI thread
10. **Testing**: Write tests for extension functionality

## Example: Complete Extension

See the full example extension implementation in the `tom_ai_build/vscode_extension/` directory (to be created).

## Next Steps

1. Set up extension development environment
2. Implement core commands (run script, generate docs)
3. Create VS Code API bridge for D4rt
4. Add Copilot integration for AI-powered operations
5. Implement progress reporting and error handling
6. Add configuration options
7. Write tests
8. Package and publish extension
