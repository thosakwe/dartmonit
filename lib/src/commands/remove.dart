import 'dart:io';
import 'package:args/command_runner.dart';
import '../client.dart';
import 'common.dart';

class RemoveCommand extends Command {
  @override
  String get name => 'remove';

  @override
  String get description =>
      'Removes a command from the list of processes to execute.';

  RemoveCommand() {
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
    var info = await client.remove(name);
    client.close();

    print('The removed process ($name):\n');
    printStatus(info);
    exit(0);
  }
}
