/// Where a project or workspace keeps its guidelines.
library;

import 'dart:io';

import 'package:path/path.dart' as path;

/// The name of a guidelines folder.
const kAgentGuidelinesFolder = '_agent_guidelines';

/// The old name of a guidelines folder, still read where the new one is
/// missing (other workspaces, older checkouts).
const kCopilotGuidelinesFolder = '_copilot_guidelines';

/// The guidelines folder of [dir]: `<dir>/_agent_guidelines` when it exists,
/// else `<dir>/_copilot_guidelines` when that exists, else null.
Directory? guidelinesFolderOf(String dir) {
  for (final name in const [kAgentGuidelinesFolder, kCopilotGuidelinesFolder]) {
    final folder = Directory(path.join(dir, name));
    if (folder.existsSync()) return folder;
  }
  return null;
}
