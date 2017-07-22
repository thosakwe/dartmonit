import 'dart:io';
import 'dart:isolate';
import 'package:args/command_runner.dart';
import 'package:resource/resource.dart';
import '../scripts/service.dart';

final Directory pubCacheBinDir =
    new Directory.fromUri(pubCacheDir.uri.resolve('bin'));
final File dartmonitBat =
    new File.fromUri(pubCacheBinDir.uri.resolve('dartmonit.bat'));

class InstallCommand extends Command {
  @override
  String get name => 'install';

  @override
  String get description => 'Configures dartmonit to run at startup.';

  @override
  run() async {
    if (Platform.isWindows) {
      // Build snapshot
      if (await dartmonSnapshot.exists()) await dartmonSnapshot.delete();
      if (!await dartmonSnapshot.parent.exists())
        await dartmonSnapshot.parent.create(recursive: true);

      print('Building dartmon snapshot..');
      var buildSnapshot = await Process.run(Platform.resolvedExecutable, [
        '--snapshot=${dartmonSnapshot.absolute.path}',
        Platform.script.toFilePath()
      ]);

      if (buildSnapshot.exitCode != 0) {
        var cmd =
            '${Platform.resolvedExecutable} --snapshot="${dartmonSnapshot.absolute.path}" ${Platform.script.toFilePath()}';
        stderr.writeln('$cmd exited with code ${buildSnapshot.exitCode}');
        stderr.writeln(buildSnapshot.stdout);
        stderr.writeln(buildSnapshot.stderr);
        exit(1);
        return;
      }

      var dartmonitUri = await Isolate.resolvePackageUri(Uri.parse(
          'package:dartmonit/src/scripts/DartmonitWindowsService/DartmonitWindowsService/bin/Release/DartmonitWindowsService.exe'));
      var dartmonitServiceFile = new File.fromUri(dartmonitUri);
      var user = Platform.environment['USERNAME'];

      print(
          'To run the dartmonit service as $user, it must provide the correct password to sc.exe');
      print('dartmonit will not save your password.');
      stdout.write('\nPlease enter the password for $user: ');

      var password = stdin.readLineSync();

      var sc = await Process.run('sc', [
        'create',
        'dartmonit',
        'binpath="${dartmonitServiceFile.absolute.path}"',
        'obj=.\\$user',
        'password=$password',
        'DisplayName=dartmonit daemon',
        'start=auto'
      ]);

      if (sc.exitCode != 0) {
        stderr.writeln(
            'sc create dartmonit binpath="${dartmonitServiceFile.absolute.path}" obj=.\\$user password=$password DisplayName=dartmonit daemon start=auto exited with code ${sc.exitCode}');
        stderr.writeln(sc.stdout);
        stderr.writeln(sc.stderr);
        exit(1);
        return;
      }

      var start = await Process.run('sc', ['start', 'dartmonit']);

      if (start.exitCode != 0) {
        stderr
            .writeln('"sc start dartmonit" exited with code ${start.exitCode}');
        stderr.writeln(start.stdout);
        stderr.writeln(start.stderr);
        exit(1);
        return;
      }
    } else {
      var scriptFile = new File('/etc/init.d/dartmonit');
      var logFile = new File('/var/log/dartmonit.log');

      if (!await scriptFile.exists()) await scriptFile.create(recursive: true);

      var sink = scriptFile.openWrite();
      var resx = new Resource('package:dartmonit/src/scripts/service.g.dart');
      await resx.openRead().pipe(sink);

      print('Successfully wrote ${scriptFile.absolute.path}');

      if (!await logFile.exists()) await logFile.create(recursive: true);
      print('Successfully touched log file ${logFile.absolute.path}');

      var chmod = await Process.run('chmod', ['+x', scriptFile.absolute.path]);

      if (chmod.exitCode != 0) {
        stderr.writeln(
            '"chmod +x ${scriptFile.absolute.path}" exited with code ${chmod
                .exitCode}');
        stderr.writeln(chmod.stdout);
        stderr.writeln(chmod.stderr);
        exit(1);
        return;
      }

      print('Successfully marked ${scriptFile.absolute.path} as executable');

      var updateRc =
          await Process.run('update-rc.d', ['dartmonit', 'defaults']);

      if (updateRc.exitCode != 0) {
        stderr.writeln(
            '"update-rc.d dartmonit defaults" exited with code ${updateRc
                .exitCode}');
        stderr.writeln(updateRc.stdout);
        stderr.writeln(updateRc.stderr);
        exit(1);
        return;
      }
    }

    print('Successfully configured dartmonit to run at startup.');
    exit(0);
  }
}
