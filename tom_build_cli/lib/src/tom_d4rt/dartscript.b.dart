// D4rt Bridge - Generated file, do not edit
// Dartscript registration for tom_build_cli
// Generated: 2026-06-17T18:45:41.406194

/// D4rt Bridge Registration for tom_build_cli
library;

import 'package:tom_d4rt/d4rt.dart';
import 'package:tom_d4rt_dcli/dartscript.b.dart' as imported_0;
import 'tom_build_cli_bridges.b.dart' as tom_build_cli_bridges;
import 'relaxers.b.dart' as relaxer_factories;

/// Combined bridge registration for tom_build_cli.
class TomBuildCliBridges {
  /// Register all bridges with D4rt interpreter.
  static void register([D4rt? interpreter]) {
    final d4rt = interpreter ?? D4rt();

    // Register imported bridges
    imported_0.TomD4rtDcliBridge.register(d4rt);

    // Register local bridges
    tom_build_cli_bridges.TomBuildCliBridge.registerBridges(
      d4rt,
      'package:tom_build_cli/tom_build_cli.dart',
    );
    // Register under sub-package barrels for direct imports
    for (final barrel in tom_build_cli_bridges.TomBuildCliBridge.subPackageBarrels()) {
      tom_build_cli_bridges.TomBuildCliBridge.registerBridges(d4rt, barrel);
    }

    // RC-2: Register generic constructor factories
    relaxer_factories.registerGenericConstructors();
    // GEN-079: Register relaxer wrapper factories
    relaxer_factories.registerRelaxers();
  }

  /// Get import block for all modules.
  static String getImportBlock() {
    final buffer = StringBuffer();
    buffer.writeln(imported_0.TomD4rtDcliBridge.getImportBlock());
    buffer.writeln(tom_build_cli_bridges.TomBuildCliBridge.getImportBlock());
    return buffer.toString();
  }
}
