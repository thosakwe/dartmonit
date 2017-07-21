import 'dart:io';
import 'package:args/command_runner.dart';
import '../client.dart';
import 'common.dart';

class StatusCommand extends Command {
  @override
  String get name => 'status';

  @override
  String get description => 'Fetches the status of a given process.';

  StatusCommand() {
    addClientArgs(argParser);
  }

  @override
  run() async {
    var host = argResults['host'];
    var port = int.parse(argResults['port']);
    var baseUrl = 'http://$host:$port';

    if (argResults.rest.isEmpty)
      throw 'fatal error: no process name provided';

    var client = new DartmonClient(baseUrl);

    try {
      if (argResults.rest.first == 'all') {
        var info = await client.fetchAll();

        if (info.isEmpty) {
          print('There are no processes running.');
          exit(0);
          return;
        }

        client.close();
        info.forEach(printStatus);
        exit(0);
      }

      var info = await client.fetch(argResults.rest.first);
      client.close();

      printStatus(info);
      exit(0);
    } catch(e) {
      client.close();
      rethrow;
    }
  }
}