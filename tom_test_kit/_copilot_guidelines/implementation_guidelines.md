# Tom Test Kit — Implementation Guidelines

This document defines core implementation rules for `tom_test_kit`.

---

## Critical Rule: tom_build_base Owns Shared CLI Functionality

If functionality logically belongs to `tom_build_base`, it must be implemented and released there first.

Mandatory workflow:

1. Modify `tom_build_base`.
2. Test it with a test tool created inside `tom_build_base` (or an existing one there).
3. Republish `tom_build_base`.
4. Update the `tom_build_base` version in all tools based on `tom_build_base`.
5. Run tests in all tools based on `tom_build_base`.

Hard constraints:

- Never add temporary downstream code in `tom_test_kit` for functionality that belongs to `tom_build_base`.
- Never implement stopgap copies in tool packages when the owning library is `tom_build_base`.
- If integration cannot be completed in one pass, explicitly tell the user and make an integration plan first.

---

## Quality Gate

Before marking work complete:

- Run `dart analyze` and resolve issues in the affected package.
- Run relevant tests for changed behavior.
- Keep changes in `tom_test_kit` focused on tool-specific behavior, not shared CLI framework behavior.
