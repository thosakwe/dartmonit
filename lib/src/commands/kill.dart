import 'dart:io';
import 'package:args/command_runner.dart';
import '../client.dart';
import 'common.dart';

class KillCommand extends Command {
  @override
  String get name => 'kill';

  @override
  String get description =>
      'Halts the execution of a given command.';

  KillCommand() {
    addClientArgs(argParser);
  }

  @override
  run() async {
    var host = argResults['host'];
    var port = int.parse(argResults['port']);
    var baseUrl = 'http://$host:$port';

    if (argResults.rest.isEmpty) throw 'fatal error: no name provided';

    var name = argResults.rest.first;
    var client = new DartmonClient(baseUrl);
    var info = await client.kill(name);
    client.close();

    printStatus(info);
    exit(0);
  }
}
