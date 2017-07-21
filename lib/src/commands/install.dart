import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:resource/resource.dart';

class InstallCommand extends Command {
  @override
  String get name => 'install';

  @override
  String get description =>
      'Adds a shell script to /etc/init.d to run dartmon on startup.';

  @override
  run() async {
    if (Platform.isWindows) {
      stderr.writeln('dartmon does not support being installed as a daemon on Windows.');
      exit(1);
      return;
    }

    var scriptFile = new File('/etc/init.d/dartmon.sh');
    var logFile = new File('/var/log/dartmon.log');

    if (!await scriptFile.exists()) await scriptFile.create(recursive: true);

    var sink = scriptFile.openWrite();
    var resx = new Resource('package:dartmon/src/scripts/service.sh');
    await resx.openRead().pipe(sink);

    print('Successfully wrote ${scriptFile.absolute.path}');


    if (!await logFile.exists()) await logFile.create(recursive: true);
    print('Successfully touched log file ${logFile.absolute.path}');

    var chmod = await Process.run('chmod', ['+x', scriptFile.absolute.path]);

    if (chmod.exitCode != 0) {
      stderr.writeln(
          '"chmod +x ${scriptFile.absolute.path}" exited with code ${chmod.exitCode}');
      stderr.writeln(chmod.stdout);
      stderr.writeln(chmod.stderr);
      exit(1);
      return;
    }

    print('Successfully marked ${scriptFile.absolute.path} as executable');

    var updateRc = await Process.run('update-rc.d', ['dartmon', 'defaults']);

    if (updateRc.exitCode != 0) {
      stderr.writeln(
          '"update-rc.d dartmon defaults" exited with code ${updateRc.exitCode}');
      stderr.writeln(updateRc.stdout);
      stderr.writeln(updateRc.stderr);
      exit(1);
      return;
    }

    print('Successfully configured dartmon to run at startup');
    exit(0);
  }
}
