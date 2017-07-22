import 'dart:io';
import 'package:args/command_runner.dart';
import '../scripts/service.dart';

class UninstallCommand extends Command {
  @override
  String get name => 'uninstall';

  @override
  String get description => 'Uninstalls the dartmonit daemon.';

  @override
  run() async {
    print(
        'Please confirm that you want to uninstall the dartmonit service. This cannot be undone.');
    stderr.write('\nUninstall dartmonit [y|N] ');
    var sure = stdin.readLineSync();

    if (sure == 'y') {
      if (Platform.isWindows) {
        var sc = await Process.run('sc', ['stop', 'dartmonit']);
        if (sc.exitCode != 0) {
          stderr.writeln('"sc stop dartmonit" exited with code ${sc.exitCode}');
          if (sc.stdout.isNotEmpty) stdout.writeln(sc.stdout);
          if (sc.stderr.isNotEmpty) stderr.writeln(sc.stderr);
          //throw 'Failed to stop dartmonit.';
        }
      } else {
        if (await pidFile.exists()) await stop();
        if (await pidFile.exists()) await pidFile.delete();
      }

      if (await logFile.exists()) await logFile.delete();

      if (Platform.isWindows) {
        var sc = await Process.run('sc', ['delete', 'dartmonit']);
        if (sc.exitCode != 0) {
          stderr
              .writeln('"sc delete dartmonit" exited with code ${sc.exitCode}');
          if (sc.stdout.isNotEmpty) stdout.writeln(sc.stdout);
          if (sc.stderr.isNotEmpty) stderr.writeln(sc.stderr);
          throw 'Failed to uninstall dartmonit.';
        }
      } else {
        var updateRc =
            await Process.run('update-rc.d', ['-f', 'dartmonit', 'remove']);
        if (updateRc.exitCode != 0) {
          stderr.writeln(
              '"update-rc.d -f dartmonit remove" exited with code ${updateRc.exitCode}');
          if (updateRc.stdout.isNotEmpty) stdout.writeln(updateRc.stdout);
          if (updateRc.stderr.isNotEmpty) stderr.writeln(updateRc.stderr);
          throw 'Failed to uninstall dartmonit.';
        }
      }

      print('Successfully uninstalled dartmonit.');
    } else {
      print('Not uninstalling the dartmonit service.');
    }
  }
}
