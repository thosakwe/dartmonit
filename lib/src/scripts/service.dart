#!/usr/bin/env dart
import 'dart:async';
import 'dart:io';

final File pidFile = new File('/var/run/dartmonit.pid');
final File logFile = new File('/var/log/darmonit.log');
final File homeDirFile = new File('/etc/dartmonit/home_dir.txt');
var homeDirPath = (Platform.isWindows
        ? Platform.environment['USERPROFILE']
        : Platform.environment['HOME']) ??
    homeDirFile.readAsStringSync();
final Directory homeDir = new Directory(homeDirPath);
final Directory pubCacheDir = new Directory.fromUri(Platform.isWindows
    ? homeDir.uri.resolve('AppData/Roaming/Pub/Cache')
    : homeDir.uri.resolve('.pub-cache'));
final File dartExecutable = new File(Platform.resolvedExecutable);
final File windowsPubExecutable =
    new File.fromUri(dartExecutable.uri.resolve('../bin/pub.bat'));
final File dartmonSnapshot = new File.fromUri(pubCacheDir.uri
    .resolve('global_packages/dartmonit/bin/dartmon.dart.snapshot'));

main(List<String> args) async {
  try {
    if (args.isEmpty) {
      stderr.writeln(
          'fatal error: no argument provided (expected start|stop|restart|status)');
      exitCode = 1;
    } else {
      switch (args.first) {
        case 'start':
          return await start();
        case 'stop':
          return await stop();
        case 'restart':
          return await restart();
        case 'status':
          return await status();
        default:
          stderr.writeln('unrecognized option: "${args.first}"');
          exitCode = 1;
          break;
      }
    }
  } catch (e, st) {
    stderr..writeln(e)..writeln(st);

    try {
      var sink = logFile.openWrite(mode: FileMode.APPEND);
      sink..writeln(e)..writeln(st);
    } catch (_) {}
  }
}

Future start() async {
  if (await pidFile.exists()) {
    print('dartmonit is already running.');
    exitCode = 1;
  } else {
    print('Starting dartmonit...');
    Process process;

    if (Platform.isWindows) {
      process = await Process.start(windowsPubExecutable.absolute.path,
          ['global', 'run', 'dartmonit:dartmon', 'start'],
          mode: ProcessStartMode.DETACHED);
    } else {
      process = await Process.start('sudo',
          [Platform.resolvedExecutable, dartmonSnapshot.absolute.path, 'start'],
          mode: ProcessStartMode.DETACHED_WITH_STDIO);
    }
    if (!await pidFile.exists()) await pidFile.create(recursive: true);
    await pidFile.writeAsString(process.pid.toString());

    if (!await logFile.exists()) await logFile.create(recursive: true);
    await logFile.writeAsString('dartmonit started with PID ${process.pid}',
        mode: FileMode.APPEND);

    print('dartmonit started with PID ${process.pid}');
  }
}

Future stop() async {
  if (!await pidFile.exists()) {
    print('dartmonit is not running.');
    exitCode = 1;
  } else {
    var contents = await pidFile.readAsString();
    var pid = int.parse(contents);

    if (!Process.killPid(pid)) {
      stderr.writeln('Could not kill dartmonit process with PID $pid');
      exitCode = 1;
    } else {
      await pidFile.delete();
      print('dartmonit process with PID $pid stopped');
    }
  }
}

Future restart() => stop().then((_) => start());

Future status() async {
  if (!await pidFile.exists()) {
    print('dartmonit is not running.');
  } else {
    var contents = await pidFile.readAsString();
    var pid = int.parse(contents);

    print('dartmonit is running; PID $pid');
    print('Run "dartmonit status all" to view the status of all scripts.');
  }
}