import 'dart:io';

import 'package:tom_build_cli/tom_build_cli.dart';

void main(List<String> args) async {
  // Determine execution mode based on arguments
  final mode = determineExecutionMode(args);
  
  switch (mode) {
    case TomExecutionMode.tomD4rt:
      // Forward to TomD4rt REPL or script execution
      final exitCode = await runTomD4rt(args);
      exit(exitCode);
    
    case TomExecutionMode.tomCommand:
      // Execute Tom CLI commands
      final cli = TomCli();
      final result = await cli.run(args);

      if (result.message != null && result.message!.isNotEmpty) {
        print(result.message);
      }

      if (result.error != null && result.error!.isNotEmpty) {
        stderr.writeln(result.error);
      }

      exit(result.exitCode);
  }
}
