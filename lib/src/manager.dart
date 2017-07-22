import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:angel_framework/angel_framework.dart';
import 'package:path/path.dart' as p;

class ChildProcessManager {
  static Directory _dartmonDir;
  static File _dartmonQueueFile;
  static String _userHome;
  final Map<String, ChildProcessInfo> _processes = {};

  static String get userHome => _userHome ??= (Platform.isWindows
      ? Platform.environment['USERPROFILE']
      : Platform.environment['HOME']);

  static Future<Directory> resolveDartmonDir() async {
    if (_dartmonDir != null)
      return _dartmonDir;
    else {
      var dir = _dartmonDir = new Directory.fromUri(
          new Directory(userHome).uri.resolve('.dartmonit'));
      if (!await dir.exists()) await dir.create(recursive: true);
      return _dartmonDir;
    }
  }

  static Future<File> resolveDartmonQueueFile() async {
    if (_dartmonQueueFile != null) return _dartmonQueueFile;
    var dir = await resolveDartmonDir();
    var file = new File.fromUri(dir.uri.resolve('queue.txt'));
    return file;
  }

  Map<String, ChildProcessInfo> get processes =>
      new Map<String, ChildProcessInfo>.unmodifiable(_processes);

  Future<ChildProcessInfo> remove(String name) {
    if (!_processes.containsKey(name))
      throw new AngelHttpException.notFound(
          message:
              'Cannot remove process "name" - it doesn\'t exist in the queue.');
    else {
      return new Future<ChildProcessInfo>.value(_processes.remove(name));
    }
  }

  /// Check for pre-configured processes, and start them if need be.
  Future boot() async {
    var queueFile = await resolveDartmonQueueFile();

    if (await queueFile.exists()) {
      await for (var line in queueFile
          .openRead()
          .transform(UTF8.decoder)
          .transform(const LineSplitter())) {
        if (line.isNotEmpty) {
          await start(Uri.parse(line));
        }
      }
    }
  }

  /// Kill all processes, and save a list for the next run.
  Future shutdown() async {
    var queueFile = await resolveDartmonQueueFile();
    var sink = queueFile.openWrite();

    for (var info in _processes.values) {
      if (info.status) info.close();
      if (info._uri != null) sink.writeln(info._uri);
    }

    await sink.close();
  }

  Future<ChildProcessInfo> start(path) async {
    var name = p.basenameWithoutExtension(path.toString());

    if (_processes.containsKey(name)) {
      var process = _processes[name];

      if (process.status == false || process.closeReason != null) {
        _processes.remove(name);
      } else
        return process;
    }

    var file = new File.fromUri(path is Uri ? path : Uri.parse(path));
    var info = new ChildProcessInfo(file.absolute.path, name);
    _processes[name] = info;
    return info.._start();
  }
}

class ChildProcessInfo {
  final ReceivePort onCrash = new ReceivePort(), onExit = new ReceivePort();
  final String absolute, name;
  bool status;
  Isolate isolate;
  dynamic closeReason, output;
  Uri _uri;

  ChildProcessInfo(this.absolute, this.name);

  factory ChildProcessInfo.fromJson(Map map) =>
      new ChildProcessInfo(map['absolute'], map['name'])
        ..status = map['status']
        ..closeReason = map['close_reason']
        ..output = map['output'];

  void close() {
    onCrash.close();
    onExit.close();
    isolate.kill();
    closeReason = 'User-initiated shutdown';
    status = false;
  }

  void _start() {
    onCrash.listen((error) {
      print('$name crashed with $error');
      this
        ..status = false
        ..closeReason = error;
    });

    onExit.listen((output) {
      print('$name exited with $output');
      this
        ..closeReason = 'Successful exit'
        ..output = output;
    });

    Isolate
        .spawnUri(_uri = new File(absolute).uri, [], null,
            errorsAreFatal: true, onError: onCrash.sendPort)
        .timeout(const Duration(minutes: 1))
        .then((isolate) {
      this
        ..isolate = isolate
        ..status = true;
    }).catchError((e) {
      this
        ..status = false
        ..closeReason = e;
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'absolute': absolute,
      'name': name,
      'status': status,
      'close_reason': closeReason?.toString(),
      'output': output
    };
  }
}
