import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dartmon/src/commands/kill.dart';
import 'package:dartmon/src/commands/install.dart';
import 'package:dartmon/src/commands/run.dart';
import 'package:dartmon/src/commands/start.dart';
import 'package:dartmon/src/commands/status.dart';
import 'package:dartmon/src/commands/stop.dart';

final CommandRunner commandRunner = new CommandRunner(
    'dartmon', 'Monitor Dart scripts, and run them on startup.')
  ..addCommand(new KillCommand())
  ..addCommand(new InstallCommand())
  ..addCommand(new StartCommand())
  ..addCommand(new RunCommand())
  ..addCommand(new StatusCommand())
  ..addCommand(new StopCommand());

main(List<String> args) => commandRunner.run(args).catchError((e, st) {
      stderr..writeln(e)..writeln(st);
    });
