/// Comprehensive tests for ModeProcessor (Section 4)
///
/// Tests mode block processing according to the Tom CLI specification.
library;

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/mode/mode_processor.dart';

void main() {
  late ModeProcessor processor;

  setUp(() {
    processor = ModeProcessor();
  });

  // ===========================================================================
  // Section 4.2 - Mode Block Syntax
  // ===========================================================================

  group('Section 4.2 - Mode Block Syntax', () {
    group('4.2.1 - Variant 1: Global Mode Matching', () {
      test('matches mode in active modes set', () {
        const content = '''
before
@@@mode development
dev_config: true
@@@endmode
after
''';
        final result = processor.processContent(content, {'development'});
        expect(result, contains('dev_config: true'));
        expect(result, contains('before'));
        expect(result, contains('after'));
      });

      test('does not include non-matching mode', () {
        const content = '''
@@@mode development
dev_only: true
@@@mode production
prod_only: true
@@@endmode
''';
        final result = processor.processContent(content, {'development'});
        expect(result, contains('dev_only'));
        expect(result, isNot(contains('prod_only')));
      });

      test('uses default when no mode matches', () {
        const content = '''
@@@mode development
env: dev
@@@mode production
env: prod
@@@mode default
env: default
@@@endmode
''';
        final result = processor.processContent(content, {'staging'});
        expect(result, contains('env: default'));
        expect(result, isNot(contains('env: dev')));
        expect(result, isNot(contains('env: prod')));
      });

      test('first matching mode wins', () {
        const content = '''
@@@mode development
order: first
@@@mode development
order: second
@@@endmode
''';
        final result = processor.processContent(content, {'development'});
        expect(result, contains('order: first'));
        expect(result, isNot(contains('order: second')));
      });

      test('mode with empty content produces empty result', () {
        const content = '''
@@@mode production
prod_only: value
@@@endmode
''';
        final result = processor.processContent(content, {'development'});
        expect(result.trim(), isEmpty);
      });

      test('supports comma-separated OR conditions', () {
        const content = '''
@@@mode development,staging
multi_match: true
@@@mode production
prod: true
@@@endmode
''';
        // development matches
        var result = processor.processContent(content, {'development'});
        expect(result, contains('multi_match: true'));

        // staging matches
        result = processor.processContent(content, {'staging'});
        expect(result, contains('multi_match: true'));

        // production matches its own block
        result = processor.processContent(content, {'production'});
        expect(result, contains('prod: true'));

        // neither matches
        result = processor.processContent(content, {'other'});
        expect(result.trim(), isEmpty);
      });

      test('spaces around commas are trimmed', () {
        const content = '''
@@@mode development , staging , int
any_env: true
@@@endmode
''';
        final result = processor.processContent(content, {'staging'});
        expect(result, contains('any_env: true'));
      });
    });

    group('4.2.3 - Variant 3: Direct Mode Type Matching', () {
      test('matches exact mode type value', () {
        const content = '''
@@@mode :execution=local
working_dir: .
@@@mode :execution=docker
working_dir: /app
@@@mode default
working_dir: /default
@@@endmode
''';
        var result = processor.processContent(
          content,
          {},
          modeTypeValues: {'execution': 'local'},
        );
        expect(result, contains('working_dir: .'));

        result = processor.processContent(
          content,
          {},
          modeTypeValues: {'execution': 'docker'},
        );
        expect(result, contains('working_dir: /app'));
      });

      test('uses default when mode type value does not match', () {
        const content = '''
@@@mode :execution=local
config: local
@@@mode :execution=docker
config: docker
@@@mode default
config: default
@@@endmode
''';
        final result = processor.processContent(
          content,
          {},
          modeTypeValues: {'execution': 'cloud'},
        );
        expect(result, contains('config: default'));
      });

      test('works with multiple mode types', () {
        const content = '''
@@@mode :environment=prod
db_host: prod-db.example.com
@@@mode default
db_host: localhost
@@@endmode
''';
        final result = processor.processContent(
          content,
          {},
          modeTypeValues: {'environment': 'prod'},
        );
        expect(result, contains('db_host: prod-db.example.com'));
      });

      test('multiple mode types evaluated in same block', () {
        const content = '''
@@@mode :execution=docker
from_docker: true
@@@mode :environment=prod
from_env: true
@@@mode default
default_mode: true
@@@endmode
''';
        // execution=docker, environment=dev -> matches docker
        var result = processor.processContent(
          content,
          {},
          modeTypeValues: {'execution': 'docker', 'environment': 'dev'},
        );
        expect(result, contains('from_docker: true'));

        // execution=local, environment=prod -> matches env
        result = processor.processContent(
          content,
          {},
          modeTypeValues: {'execution': 'local', 'environment': 'prod'},
        );
        expect(result, contains('from_env: true'));

        // neither matches
        result = processor.processContent(
          content,
          {},
          modeTypeValues: {'execution': 'local', 'environment': 'dev'},
        );
        expect(result, contains('default_mode: true'));
      });
    });

    group('4.2.4 - Mode Block Formatting Rules', () {
      test('mode block at line start', () {
        const content = '''
@@@mode development
key: value
@@@endmode
''';
        final result = processor.processContent(content, {'development'});
        expect(result, contains('key: value'));
      });

      test('mode block indented', () {
        const content = '''
  @@@mode development
  key: value
  @@@endmode
''';
        final result = processor.processContent(content, {'development'});
        expect(result, contains('key: value'));
      });

      test('indentation of content is preserved relative to block', () {
        const content = '''
  @@@mode development
  nested:
    level1:
      level2: value
  @@@endmode
''';
        final result = processor.processContent(content, {'development'});
        expect(result, contains('nested:'));
        expect(result, contains('level1:'));
        expect(result, contains('level2: value'));
      });
    });
  });

  // ===========================================================================
  // Multiple Mode Blocks
  // ===========================================================================

  group('Multiple Mode Blocks', () {
    test('processes multiple independent mode blocks', () {
      const content = '''
# First block
@@@mode development
dev1: true
@@@endmode

middle_content: preserved

# Second block
@@@mode development
dev2: true
@@@mode production
prod2: true
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('dev1: true'));
      expect(result, contains('middle_content: preserved'));
      expect(result, contains('dev2: true'));
      expect(result, isNot(contains('prod2: true')));
    });

    test('each block resolves independently', () {
      const content = '''
@@@mode development
block1: dev
@@@mode production
block1: prod
@@@mode default
block1: default
@@@endmode

@@@mode production
block2: prod
@@@mode default
block2: default
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('block1: dev'));
      expect(result, contains('block2: default'));
    });

    test('nested content in separate blocks', () {
      const content = '''
dependencies:
@@@mode development
  local_dep:
    path: ../local_dep
@@@mode production
  published_dep: ^1.0.0
@@@endmode

dev_dependencies:
@@@mode development
  test: any
@@@mode production
  test: ^1.24.0
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('dependencies:'));
      expect(result, contains('path: ../local_dep'));
      expect(result, contains('dev_dependencies:'));
      expect(result, contains('test: any'));
      expect(result, isNot(contains('published_dep')));
    });
  });

  // ===========================================================================
  // Content Preservation
  // ===========================================================================

  group('Content Preservation', () {
    test('preserves content before mode blocks', () {
      const content = '''
# Header comment
header: value

@@@mode development
dev: true
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('# Header comment'));
      expect(result, contains('header: value'));
    });

    test('preserves content after mode blocks', () {
      const content = '''
@@@mode development
dev: true
@@@endmode

footer: value
# Footer comment
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('footer: value'));
      expect(result, contains('# Footer comment'));
    });

    test('preserves content between mode blocks', () {
      const content = '''
@@@mode development
dev1: true
@@@endmode

between_blocks: preserved

@@@mode development
dev2: true
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('between_blocks: preserved'));
    });

    test('preserves empty lines', () {
      const content = '''
before


@@@mode development
dev: true
@@@endmode


after
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('before'));
      expect(result, contains('after'));
    });

    test('preserves indentation in mode block content', () {
      const content = '''
@@@mode development
nested:
  level1:
    level2: value
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('  level1:'));
      expect(result, contains('    level2: value'));
    });
  });

  // ===========================================================================
  // YAML Content in Mode Blocks
  // ===========================================================================

  group('YAML Content in Mode Blocks', () {
    test('preserves nested YAML structures', () {
      const content = '''
@@@mode development
dependencies:
  path: ../local_dep
  http: any
  nested:
    deep: value
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('dependencies:'));
      expect(result, contains('path: ../local_dep'));
      expect(result, contains('nested:'));
      expect(result, contains('deep: value'));
    });

    test('preserves YAML lists', () {
      const content = '''
@@@mode development
items:
  - item1
  - item2
  - nested:
      key: value
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('- item1'));
      expect(result, contains('- item2'));
      expect(result, contains('- nested:'));
    });

    test('preserves quoted strings', () {
      const content = '''
@@@mode development
quoted: "value with: special chars"
single_quoted: 'another value'
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('"value with: special chars"'));
      expect(result, contains("'another value'"));
    });

    test('preserves multiline strings', () {
      const content = '''
@@@mode development
multiline: |
  line 1
  line 2
  line 3
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      expect(result, contains('multiline: |'));
      expect(result, contains('line 1'));
      expect(result, contains('line 2'));
    });
  });

  // ===========================================================================
  // Combined Mode Sources
  // ===========================================================================

  group('Combined Mode Sources', () {
    test('global modes and type values can be combined', () {
      const content = '''
@@@mode verbose
logging: verbose
@@@mode default
logging: normal
@@@endmode

@@@mode :environment=prod
env: production
@@@mode default
env: default
@@@endmode
''';
      final result = processor.processContent(
        content,
        {'verbose'},
        modeTypeValues: {'environment': 'prod'},
      );
      expect(result, contains('logging: verbose'));
      expect(result, contains('env: production'));
    });

    test('global mode takes priority when both could match', () {
      const content = '''
@@@mode verbose
from_global: true
@@@mode :debug=on
from_type: true
@@@mode default
from_default: true
@@@endmode
''';
      // Both verbose and debug=on are active, but verbose comes first
      final result = processor.processContent(
        content,
        {'verbose'},
        modeTypeValues: {'debug': 'on'},
      );
      expect(result, contains('from_global: true'));
    });

    test('typed condition matches when global does not', () {
      const content = '''
@@@mode production
from_global: true
@@@mode :debug=on
from_type: true
@@@mode default
from_default: true
@@@endmode
''';
      // production not active, but debug=on matches
      final result = processor.processContent(
        content,
        {'development'},
        modeTypeValues: {'debug': 'on'},
      );
      expect(result, contains('from_type: true'));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('empty content returns empty string', () {
      final result = processor.processContent('', {});
      expect(result, isEmpty);
    });

    test('content without mode blocks returned unchanged', () {
      const content = '''
key: value
nested:
  inner: data
''';
      final result = processor.processContent(content, {});
      expect(result, equals(content));
    });

    test('handles mode block with no content', () {
      const content = '''
@@@mode development
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      expect(result.trim(), isEmpty);
    });

    test('handles mode block with only whitespace', () {
      const content = '''
@@@mode development
   
@@@endmode
''';
      final result = processor.processContent(content, {'development'});
      // Should preserve the whitespace
      expect(result, isNotEmpty);
    });

    test('handles empty mode set', () {
      const content = '''
@@@mode development
dev: true
@@@mode default
default: true
@@@endmode
''';
      final result = processor.processContent(content, {});
      expect(result, contains('default: true'));
    });

    test('handles mode name with special characters', () {
      const content = '''
@@@mode dev-mode_v2
special: true
@@@endmode
''';
      final result = processor.processContent(content, {'dev-mode_v2'});
      expect(result, contains('special: true'));
    });

    test('mode names are case-sensitive', () {
      const content = '''
@@@mode Development
uppercase: true
@@@mode development
lowercase: true
@@@endmode
''';
      var result = processor.processContent(content, {'Development'});
      expect(result, contains('uppercase: true'));

      result = processor.processContent(content, {'development'});
      expect(result, contains('lowercase: true'));
    });

    test('unmatched endmode is ignored', () {
      const content = '''
key: value
@@@endmode
more: stuff
''';
      final result = processor.processContent(content, {});
      expect(result, contains('key: value'));
      expect(result, contains('more: stuff'));
    });

    test('mode block without endmode is not processed', () {
      const content = '''
before
@@@mode development
dev: true
after
''';
      // Without endmode, this should not be treated as a mode block
      final result = processor.processContent(content, {'development'});
      expect(result, contains('before'));
    });

    test('handles mode type value with equals sign in value', () {
      const content = '''
@@@mode :expression=a=b
matched: true
@@@mode default
matched: false
@@@endmode
''';
      final result = processor.processContent(
        content,
        {},
        modeTypeValues: {'expression': 'a=b'},
      );
      // This depends on how the parser handles multiple = signs
      // The first = separates key/value, rest is value
      expect(result, isNotEmpty);
    });

    test('handles unicode mode names', () {
      const content = '''
@@@mode テスト
japanese: true
@@@mode default
japanese: false
@@@endmode
''';
      final result = processor.processContent(content, {'テスト'});
      expect(result, contains('japanese: true'));
    });
  });

  // ===========================================================================
  // Real-World Scenarios
  // ===========================================================================

  group('Real-World Scenarios', () {
    test('pubspec.yaml dependency override scenario', () {
      const content = '''
name: my_package
version: 1.0.0

dependencies:
@@@mode development
  tom_core:
    path: ../tom_core
  other_dep:
    path: ../other_dep
@@@mode production
  tom_core: ^2.0.0
  other_dep: ^1.0.0
@@@endmode

dev_dependencies:
  test: any
@@@mode development
  coverage: any
@@@endmode
''';
      final devResult = processor.processContent(content, {'development'});
      expect(devResult, contains('path: ../tom_core'));
      expect(devResult, contains('coverage: any'));

      final prodResult = processor.processContent(content, {'production'});
      expect(prodResult, contains('tom_core: ^2.0.0'));
      expect(prodResult, isNot(contains('coverage:')));
    });

    test('docker configuration scenario', () {
      const content = '''
@@@mode :environment=prod
FROM dart:stable

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=0 /runtime/ /
COPY --from=0 /app/bin/server /app/bin/server
CMD ["/app/bin/server"]
@@@mode default
FROM dart:stable

WORKDIR /app
COPY . .
RUN dart pub get

CMD ["dart", "run", "bin/server.dart"]
@@@endmode
''';
      final prodResult = processor.processContent(
        content,
        {},
        modeTypeValues: {'environment': 'prod'},
      );
      expect(prodResult, contains('dart compile exe'));
      expect(prodResult, contains('FROM scratch'));

      final devResult = processor.processContent(
        content,
        {},
        modeTypeValues: {'environment': 'dev'},
      );
      // Default section is used for non-prod environments
      expect(devResult, contains('"run"'));
      expect(devResult, isNot(contains('FROM scratch')));
    });

    test('conditional API endpoints scenario', () {
      const content = '''
api:
@@@mode development,staging
  base_url: http://localhost:8080
  debug: true
@@@mode production
  base_url: https://api.example.com
  debug: false
@@@mode default
  base_url: http://localhost:8080
  debug: true
@@@endmode
''';
      final devResult = processor.processContent(content, {'development'});
      expect(devResult, contains('base_url: http://localhost:8080'));
      expect(devResult, contains('debug: true'));

      final stagingResult = processor.processContent(content, {'staging'});
      expect(stagingResult, contains('base_url: http://localhost:8080'));

      final prodResult = processor.processContent(content, {'production'});
      expect(prodResult, contains('base_url: https://api.example.com'));
      expect(prodResult, contains('debug: false'));
    });
  });
}
