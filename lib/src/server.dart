import 'dart:async';
import 'dart:isolate';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_validate/server.dart';
import 'auth.dart';
import 'manager.dart';
import 'validators.dart';

Future<Angel> dartmonServer(
    ChildProcessManager manager, SendPort hubPort) async {
  var app = new Angel.custom(startShared)..lazyParseBodies = true;
  app.container.singleton(manager);

  // Listen for shutdown call
  var shutdown = new ReceivePort();
  shutdown.listen((_) {
    print('dartmon shutting down!!!');
    new Future.delayed(const Duration(seconds: 5)).then((_) {
      shutdown.close();
      app.close();
    });
  });

  hubPort.send(shutdown.sendPort);

  Router router = app;

  router.group('/api/processes', (router) {
    router.get('/', (ChildProcessManager manager) {
      return manager.processes.values.map<Map>((i) => i.toJson()).toList();
    });

    router.chain(resolveProcess)
      ..get('/:id', (ChildProcessInfo info) => info.toJson())
      ..delete('/:id', (ChildProcessInfo info) {
        info.close();
        return info.toJson();
      });
  });

  router.chain(validate(spawnProcess)).post('/api/spawn', spawn);

  router.post('/api/stop', (Angel app) async {
    // Send shutdown signal
    hubPort.send(true);
    return {'ok': true};
  });

  await app.configure(logRequests());
  app.justBeforeStop.add((_) => manager.shutdown());
  app.optimizeForProduction(force: true);
  return app;
}

resolveProcess(String id, ChildProcessManager manager, RequestContext req) {
  if (!manager.processes.containsKey(id)) {
    throw new AngelHttpException.notFound(
        message: 'No task named "$id" found.');
  }

  req.inject(ChildProcessInfo, manager.processes[id]);
  return true;
}

spawn(RequestContext req, ChildProcessManager manager) async {
  String path = req.body['path'];
  // TODO: Args, concurrency
  var info = await manager.start(path);
  return info.toJson();
}
