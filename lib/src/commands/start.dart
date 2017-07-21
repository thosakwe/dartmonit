import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:args/command_runner.dart';
import '../manager.dart';
import '../server.dart';

class StartCommand extends Command {
  @override
  String get name => 'start';

  @override
  String get description => 'Starts the dartmonit HTTP server.';

  StartCommand() {
    argParser
      ..addOption('concurrency',
          abbr: 'j',
          help:
              'The number of isolates to run the dartmonit HTTP server on. Default: 1',
          defaultsTo: '1')
      ..addOption('host',
          help: 'The hostname to listen at. Default: 127.0.0.1',
          defaultsTo: '127.0.0.1')
      ..addOption('port',
          abbr: 'p',
          help: 'The port for the dartmonit server to listen on. Default: 2245',
          defaultsTo: '2245');
  }

  @override
  run() async {
    var concurrency = int.parse(argResults['concurrency']);
    var hostname = argResults['host'];
    var host = await InternetAddress
        .lookup(hostname)
        .then<String>((a) => a.first.address)
        .catchError((_) {
      throw 'Invalid hostname: "$hostname"';
    });
    var port = int.parse(argResults['port']);

    var manager = new ChildProcessManager();
    await manager.boot();

    List<SendPort> shutdownListeners = [];
    var hub = new ReceivePort();

    hub.listen((data) {
      if (data is SendPort)
        shutdownListeners.add(data);
      else {
        manager.shutdown();
        shutdownListeners.forEach((s) => s.send(true));
      }
    });

    var futures = [];

    for (int i = 0; i < concurrency - 1; i++) {
      var recv = new ReceivePort(), onCrash = new ReceivePort();
      StreamSubscription successSub, crashSub;
      var c = new Completer();

      successSub = recv.listen((_) {
        successSub.cancel();
        crashSub.cancel();
        c.complete();
      }, onError: c.completeError);

      crashSub = onCrash.listen((_) {
        successSub.cancel();
        crashSub.cancel();
        c.complete();
      }, onError: c.completeError);

      futures.add(c.future.timeout(const Duration(minutes: 1)));

      Isolate.spawn(_startDartmonServer,
          [manager, host, port, recv.sendPort, hub.sendPort],
          onExit: onCrash.sendPort);
    }

    await Future.wait(futures);

    /// Start a server in this isolate, so it doesn't immediately exit.
    var app = await dartmonServer(manager, hub.sendPort);

    app.justBeforeStop.add((_) {
      hub.close();
    });

    var server = await app.startServer(new InternetAddress(host), port);
    print(
        'dartmonit HTTP listening at http://${server.address.address}:${server.port}');
  }
}

void _startDartmonServer(List args) {
  var manager = args[0] as ChildProcessManager;
  var host = new InternetAddress(args[1]);
  var port = args[2] as int;
  var sp = args[3] as SendPort;
  var hubPort = args[4] as SendPort;

  dartmonServer(manager, hubPort).then((app) async {
    await app.startServer(host, port);
    sp.send(null);
  });
}
