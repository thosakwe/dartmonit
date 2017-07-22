#!/usr/bin/env dart
import 'dart:async';
import 'dart:io';

final File pidFile = new File('/var/run/dartmonit.pid');
final File logFile = new File('/var/log/darmonit.log');
final Directory homeDir = new Directory(Platform.isWindows
    ? Platform.environment['USERPROFILE']
    : Platform.environment['HOME']);
final Directory pubCacheDir = new Directory.fromUri(Platform.isWindows
    ? homeDir.uri.resolve('AppData/Roaming/Pub/Cache')
    : homeDir.uri.resolve('.pub-cache'));
final File dartExecutable = new File(Platform.resolvedExecutable);
final File windowsPubExecutable =
    new File.fromUri(dartExecutable.uri.resolve('../bin/pub.bat'));
final File dartmonExecutable = new File.fromUri(pubCacheDir.uri
    .resolve('global_packages/dartmonit/bin/dartmon.dart.snapshot'));

main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
        'fatal error: no argument provided (expected start|stop|restart|uninstall)');
    exitCode = 1;
  } else {
    switch (args.first) {
      case 'start':
        return start();
      case 'stop':
        return stop();
      case 'restart':
        return restart();
      case 'uninstall':
        return uninstall();
      default:
        stderr.writeln('unrecognized option: "${args.first}"');
        exitCode = 1;
        break;
    }
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
      process = await Process.start(Platform.resolvedExecutable,
          [dartmonExecutable.absolute.path, 'start'],
          mode: ProcessStartMode.DETACHED);
    }
    if (!await pidFile.exists()) await pidFile.create(recursive: true);
    await pidFile.writeAsString(process.pid.toString());
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

Future uninstall() async {
  print(
      'Please confirm that you want to uninstall the dartmonit service. This cannot be undone.');
  print(
      'Keep in mind that the generated log file (/var/log/dartmonit.log) will not be deleted.');
  stderr.write('\nUninstall dartmonit? [yes|No]');
  var sure = stdin.readLineSync();

  if (sure == 'yes') {
    if (await pidFile.exists()) await stop();
    if (await pidFile.exists()) await pidFile.delete();

    if (Platform.isWindows) {
      print('Running Windows, so skipping "update-rc.d" command');
    } else {
      var updateRc =
          await Process.run('update-rc.d', ['-f', 'dartmonit', 'remove']);

      if (updateRc.exitCode != 0) {
        stderr.writeln(
            '"update-rc.d -f dartmonit remove" exited with code ${updateRc.exitCode}');
        if (updateRc.stdout.isNotEmpty) stdout.writeln(updateRc.stdout);
        if (updateRc.stderr.isNotEmpty) stderr.writeln(updateRc.stderr);
      } else {
        print('Successfully uninstalled dartmonit.');
      }
    }
  } else {
    print('Not uninstalling the dartmonit service.');
  }
}
