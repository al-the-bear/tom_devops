## 1.0.1

- **`tom_d4rt_generator >=1.58.0`** (was `>=1.28.0`): the first release on
  `tom_analyzer_shared` 0.13.0. Its summary cache keeps no truncated bundle
  (0.12.0) and no longer deletes a bundle a concurrent run links against
  (0.13.0); both bugs silently dropped types from generated bridges. The floor
  also rules out the analyzer-10 `tom_reflection_generator` line (1.8.x).
- `D4rtInstance.evaluate` / `executeScript`: dropped a `try { return ...; }
  catch (e) { rethrow; }` that did nothing (and returned the Future unawaited
  inside the try).

## 1.0.0

- Initial version.
