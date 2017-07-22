import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dartmonit/src/commands/kill.dart';
import 'package:dartmonit/src/commands/install.dart';
import 'package:dartmonit/src/commands/remove.dart';
import 'package:dartmonit/src/commands/run.dart';
import 'package:dartmonit/src/commands/start.dart';
import 'package:dartmonit/src/commands/status.dart';
import 'package:dartmonit/src/commands/stop.dart';
import 'package:dartmonit/src/commands/uninstall.dart';

final CommandRunner commandRunner = new CommandRunner(
    'dartmonit', 'Monitor Dart scripts, and run them on startup.')
  ..addCommand(new KillCommand())
  ..addCommand(new InstallCommand())
  ..addCommand(new StartCommand())
  ..addCommand(new RemoveCommand())
  ..addCommand(new RunCommand())
  ..addCommand(new StatusCommand())
  ..addCommand(new StopCommand())
  ..addCommand(new UninstallCommand());

main(List<String> args) => commandRunner.run(args).catchError((e, st) {
      stderr..writeln(e);
      if (args.contains('-v') || args.contains('--verbose'))
        stderr..writeln(st);
      exit(1);
    });
