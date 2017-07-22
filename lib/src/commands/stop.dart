import 'dart:io';
import 'package:args/command_runner.dart';
import '../client.dart';
import 'common.dart';

class StopCommand extends Command {
  @override
  String get name => 'stop';

  @override
  String get description => 'Instructs an active dartmonit server to shut down.';

  StopCommand() {
    addClientArgs(argParser);
  }

  @override
  run() async {
    var host = argResults['host'];
    var port = int.parse(argResults['port']);
    var baseUrl = 'http://$host:$port';

    var client = new DartmonClient(baseUrl);
    await client.stop();
    client.close();

    print('Shutting down...');
  }
}