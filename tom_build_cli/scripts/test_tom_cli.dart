// D4rt Test Suite - Tom CLI API
// Run with: dart run bin/d4rtrun.b.dart scripts/test_tom_cli.dart

import 'package:tom_build_cli/tom_cli_api.dart';
import 'package:tom_d4rt_dcli/tom_d4rt_cli_api.dart';

void main() {
  // ===========================================================================
  // Test: Tom class accessibility (2 tests)
  // ===========================================================================

  verifyNotNull(Tom, 'Tom class is accessible');
  verify(true, 'Tom CLI API module loaded');

  // ===========================================================================
  // Summary
  // ===========================================================================

  testSummary();
}
