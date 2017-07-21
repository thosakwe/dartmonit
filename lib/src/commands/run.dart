import 'dart:io';
import 'package:args/command_runner.dart';
import '../client.dart';
import 'common.dart';

class RunCommand extends Command {
  @override
  String get name => 'run';

  @override
  String get description =>
      'Spawns a child process at the given absolute path.';

  RunCommand() {
    addClientArgs(argParser);
  }

  @override
  run() async {
    var host = argResults['host'];
    var port = int.parse(argResults['port']);
    var baseUrl = 'http://$host:$port';

    if (argResults.rest.isEmpty) throw 'fatal error: no input file';

    var file = new File(argResults.rest.first);
    var client = new DartmonClient(baseUrl);
    print('Starting ${file.absolute.uri.toFilePath()}...');
    var info = await client.run(file.absolute.uri.toString());
    client.close();

    printStatus(info);
    exit(0);
  }
}
