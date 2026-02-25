/// Tests for Fs scripting helper.
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build/scripting.dart';

void main() {
  group('Fs', () {
    late Directory tempTestDir;

    setUp(() {
      tempTestDir = Directory.systemTemp.createTempSync('fs_test_');
    });

    tearDown(() {
      if (tempTestDir.existsSync()) {
        tempTestDir.deleteSync(recursive: true);
      }
    });

    group('read operations', () {
      test('read returns file content', () {
        final file = File('${tempTestDir.path}/test.txt');
        file.writeAsStringSync('Hello World');

        expect(TomFs.read(file.path), 'Hello World');
      });

      test('readBytes returns file bytes', () {
        final file = File('${tempTestDir.path}/test.bin');
        file.writeAsBytesSync([0x48, 0x65, 0x6c, 0x6c, 0x6f]);

        expect(TomFs.readBytes(file.path), [0x48, 0x65, 0x6c, 0x6c, 0x6f]);
      });

      test('readLines returns file lines', () {
        final file = File('${tempTestDir.path}/test.txt');
        file.writeAsStringSync('line1\nline2\nline3');

        expect(TomFs.readLines(file.path), ['line1', 'line2', 'line3']);
      });

      test('tryRead returns content for existing file', () {
        final file = File('${tempTestDir.path}/test.txt');
        file.writeAsStringSync('content');

        expect(TomFs.tryRead(file.path), 'content');
      });

      test('tryRead returns null for non-existent file', () {
        expect(TomFs.tryRead('${tempTestDir.path}/nonexistent.txt'), isNull);
      });
    });

    group('write operations', () {
      test('write creates file with content', () {
        final path = '${tempTestDir.path}/new.txt';
        TomFs.write(path, 'content');

        expect(File(path).readAsStringSync(), 'content');
      });

      test('write creates parent directories', () {
        final path = '${tempTestDir.path}/deep/nested/dir/file.txt';
        TomFs.write(path, 'content');

        expect(File(path).existsSync(), isTrue);
        expect(File(path).readAsStringSync(), 'content');
      });

      test('writeBytes writes binary content', () {
        final path = '${tempTestDir.path}/binary.bin';
        TomFs.writeBytes(path, [1, 2, 3, 4, 5]);

        expect(File(path).readAsBytesSync(), [1, 2, 3, 4, 5]);
      });

      test('append adds content to existing file', () {
        final path = '${tempTestDir.path}/append.txt';
        TomFs.write(path, 'first');
        TomFs.append(path, 'second');

        expect(File(path).readAsStringSync(), 'firstsecond');
      });

      test('appendLine adds line with newline', () {
        final path = '${tempTestDir.path}/lines.txt';
        TomFs.appendLine(path, 'line1');
        TomFs.appendLine(path, 'line2');

        expect(File(path).readAsStringSync(), 'line1\nline2\n');
      });
    });

    group('file checks', () {
      test('exists returns true for existing file', () {
        final file = File('${tempTestDir.path}/exists.txt');
        file.writeAsStringSync('');

        expect(TomFs.exists(file.path), isTrue);
      });

      test('exists returns true for existing directory', () {
        expect(TomFs.exists(tempTestDir.path), isTrue);
      });

      test('exists returns false for non-existent path', () {
        expect(TomFs.exists('${tempTestDir.path}/nonexistent'), isFalse);
      });

      test('isFile returns true for file', () {
        final file = File('${tempTestDir.path}/file.txt');
        file.writeAsStringSync('');

        expect(TomFs.isFile(file.path), isTrue);
      });

      test('isFile returns false for directory', () {
        expect(TomFs.isFile(tempTestDir.path), isFalse);
      });

      test('isDir returns true for directory', () {
        expect(TomFs.isDir(tempTestDir.path), isTrue);
      });

      test('isDir returns false for file', () {
        final file = File('${tempTestDir.path}/file.txt');
        file.writeAsStringSync('');

        expect(TomFs.isDir(file.path), isFalse);
      });

      test('isEmpty returns true for empty file', () {
        final file = File('${tempTestDir.path}/empty.txt');
        file.writeAsStringSync('');

        expect(TomFs.isEmpty(file.path), isTrue);
      });

      test('isEmpty returns false for non-empty file', () {
        final file = File('${tempTestDir.path}/nonempty.txt');
        file.writeAsStringSync('content');

        expect(TomFs.isEmpty(file.path), isFalse);
      });

      test('isEmpty returns true for non-existent file', () {
        expect(TomFs.isEmpty('${tempTestDir.path}/nonexistent.txt'), isTrue);
      });
    });

    group('file operations', () {
      test('copy copies file to new location', () {
        final source = '${tempTestDir.path}/source.txt';
        final dest = '${tempTestDir.path}/dest.txt';
        TomFs.write(source, 'content');

        TomFs.copy(source, dest);

        expect(File(dest).readAsStringSync(), 'content');
        expect(File(source).existsSync(), isTrue); // Original still exists
      });

      test('copy copies directory recursively', () {
        final sourceDir = '${tempTestDir.path}/srcdir';
        Directory(sourceDir).createSync();
        TomFs.write('$sourceDir/file.txt', 'content');

        final destDir = '${tempTestDir.path}/destdir';
        TomFs.copy(sourceDir, destDir);

        expect(Directory(destDir).existsSync(), isTrue);
        expect(File('$destDir/file.txt').readAsStringSync(), 'content');
      });

      test('move renames file', () {
        final source = '${tempTestDir.path}/old.txt';
        final dest = '${tempTestDir.path}/new.txt';
        TomFs.write(source, 'content');

        TomFs.move(source, dest);

        expect(File(dest).existsSync(), isTrue);
        expect(File(source).existsSync(), isFalse);
      });

      test('delete removes file', () {
        final path = '${tempTestDir.path}/todelete.txt';
        TomFs.write(path, 'content');
        expect(File(path).existsSync(), isTrue);

        TomFs.delete(path);

        expect(File(path).existsSync(), isFalse);
      });

      test('delete removes directory recursively', () {
        final dir = '${tempTestDir.path}/todeleteDir';
        Directory(dir).createSync();
        TomFs.write('$dir/file.txt', 'content');

        TomFs.delete(dir, recursive: true);

        expect(Directory(dir).existsSync(), isFalse);
      });

      test('mkdir creates directory', () {
        final dir = '${tempTestDir.path}/newdir';
        TomFs.mkdir(dir);

        expect(Directory(dir).existsSync(), isTrue);
      });

      test('mkdir creates nested directories', () {
        final dir = '${tempTestDir.path}/a/b/c';
        TomFs.mkdir(dir);

        expect(Directory(dir).existsSync(), isTrue);
      });
    });

    group('listing', () {
      test('ls lists directory contents', () {
        TomFs.write('${tempTestDir.path}/a.txt', '');
        TomFs.write('${tempTestDir.path}/b.txt', '');
        Directory('${tempTestDir.path}/subdir').createSync();

        final items = TomFs.ls(tempTestDir.path);

        expect(items.length, 3);
      });

      test('ls lists recursively', () {
        TomFs.write('${tempTestDir.path}/a.txt', '');
        Directory('${tempTestDir.path}/sub').createSync();
        TomFs.write('${tempTestDir.path}/sub/b.txt', '');

        final items = TomFs.ls(tempTestDir.path, recursive: true);

        expect(items.length, 3); // a.txt, sub/, sub/b.txt
      });

      test('lsFiles lists only files', () {
        TomFs.write('${tempTestDir.path}/file.txt', '');
        Directory('${tempTestDir.path}/dir').createSync();

        final files = TomFs.files(tempTestDir.path);

        expect(files.length, 1);
        expect(files.first, endsWith('file.txt'));
      });

      test('lsDirs lists only directories', () {
        TomFs.write('${tempTestDir.path}/file.txt', '');
        Directory('${tempTestDir.path}/dir').createSync();

        final dirs = TomFs.dirs(tempTestDir.path);

        expect(dirs.length, 1);
        expect(dirs.first, endsWith('dir'));
      });
    });

    group('temp', () {
      test('creates temporary file and returns path', () {
        final path = TomFs.temp();

        expect(File(path).existsSync(), isTrue);

        // Clean up
        File(path).deleteSync();
      });

      test('creates temporary file with prefix', () {
        final path = TomFs.temp(prefix: 'mytest');

        expect(TomPth.basename(path), startsWith('mytest_'));

        // Clean up
        File(path).deleteSync();
      });

      test('creates temporary file with suffix', () {
        final path = TomFs.temp(suffix: '.txt');

        expect(path, endsWith('.txt'));

        // Clean up
        File(path).deleteSync();
      });

      test('creates temporary file with content', () {
        final path = TomFs.temp(content: 'Hello World');

        expect(File(path).readAsStringSync(), 'Hello World');

        // Clean up
        File(path).deleteSync();
      });

      test('creates temporary file with prefix, suffix, and content', () {
        final path = TomFs.temp(
          prefix: 'test',
          suffix: '.json',
          content: '{"key": "value"}',
        );

        expect(TomPth.basename(path), startsWith('test_'));
        expect(path, endsWith('.json'));
        expect(File(path).readAsStringSync(), '{"key": "value"}');

        // Clean up
        File(path).deleteSync();
      });
    });

    group('tempDir', () {
      test('creates temporary directory and returns path', () {
        final path = TomFs.tempDir();

        expect(Directory(path).existsSync(), isTrue);

        // Clean up
        Directory(path).deleteSync();
      });

      test('creates temporary directory with prefix', () {
        final path = TomFs.tempDir(prefix: 'mytest');

        expect(TomPth.basename(path), startsWith('mytest_'));

        // Clean up
        Directory(path).deleteSync();
      });
    });
  });
}
