/// D4rt Global Variables Accessor.
///
/// Provides static getters to access all known global variables from Dart
/// packages that have D4rt bridge classes. Since D4rt cannot resolve top-level
/// variables from imports, this class provides a centralized way to access
/// them via static getters that can be registered with D4rt.
///
/// ## Usage in D4rt Initialization
///
/// The initialization script uses these static getters to define global
/// variables that scripts can access:
///
/// ```dart
/// // In initialization script
/// final tom = D4rtGlobals.tom;
/// final tomExecutionContext = D4rtGlobals.tomExecutionContext;
/// ```
///
/// ## Adding New Globals
///
/// To add a new global variable:
/// 1. Import the package containing the global
/// 2. Add a static getter that returns the global
/// 3. Run `./generateAllBridge.sh -g` to regenerate bridges
/// 4. Update the initialization script to define the variable
library;

import 'package:tom_core_kernel/tom_core_kernel.dart' as core;
import 'package:tom_build/tom_build.dart' as tom_ctx;

/// Provides static access to global variables for D4rt scripts.
///
/// D4rt cannot resolve top-level variables from Dart imports, so this class
/// provides static getters that can be registered as bridged static getters,
/// allowing D4rt scripts to access global state.
class D4rtGlobals {
  // ===========================================================================
  // Tom Build Globals
  // ===========================================================================

  /// The global TomContext instance.
  ///
  /// Provides access to workspace, project, and environment information.
  /// May be uninitialized if no workspace has been set up - check
  /// `tom.isInitialized` before accessing workspace properties.
  static tom_ctx.TomContext get tom => tom_ctx.tom;

  // ===========================================================================
  // Tom Core Kernel Globals
  // ===========================================================================

  /// The global TomExecutionContext instance.
  ///
  /// Provides access to organization, application, process, and locale
  /// context entries. Use `runInContext()` to execute code with context.
  static core.TomExecutionContext get tomExecutionContext =>
      core.tomExecutionContext;

  /// The tomReflector constant for reflection annotations.
  ///
  /// Used as `@tomReflector` annotation on classes to enable reflection.
  static core.TomReflector get tomReflector => core.tomReflector;

  /// The tomComponent constant for bean registration.
  ///
  /// Used as `@tomComponent` annotation on classes to register as beans.
  static core.TomComponent get tomComponent => core.tomComponent;

  // ===========================================================================
  // Tom Core Kernel Platform Constants
  // ===========================================================================

  /// Web platform constant.
  static core.TomPlatform get platformWeb => core.platformWeb;

  /// macOS platform constant.
  static core.TomPlatform get platformMacos => core.platformMacos;

  /// Windows platform constant.
  static core.TomPlatform get platformWindows => core.platformWindows;

  /// Android platform constant.
  static core.TomPlatform get platformAndroid => core.platformAndroid;

  /// iOS platform constant.
  static core.TomPlatform get platformIos => core.platformIos;

  /// Linux platform constant.
  static core.TomPlatform get platformLinux => core.platformLinux;

  /// Fuchsia platform constant.
  static core.TomPlatform get platformFuchsia => core.platformFuchsia;

  // ===========================================================================
  // Tom Core Kernel Environment Constants
  // ===========================================================================

  /// Default environment constant.
  static core.TomEnvironment get defaultTomEnvironment =>
      core.defaultTomEnvironment;

  /// No environment constraint sentinel.
  static core.TomEnvironment get noTomEnvironment => core.noTomEnvironment;

  /// No platform constraint sentinel.
  static core.TomPlatform get noTomPlatform => core.noTomPlatform;
}
