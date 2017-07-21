import 'package:args/args.dart';
import '../manager.dart';

void addClientArgs(ArgParser argParser) {
  argParser
    ..addOption('host',
        help: 'The hostname to connect to. Default: 127.0.0.1',
        defaultsTo: '127.0.0.1')
    ..addOption('port',
        abbr: 'p', help: 'The port to connect to.', defaultsTo: '2245');
}

void printStatus(ChildProcessInfo info) {
  String status;

  switch (info.status) {
    case true:
      status = info.closeReason == null ? 'RUNNING' : 'COMPLETED';
      break;
    case false:
      status =
          info.closeReason == 'User-initiated shutdown' ? 'HALTED' : 'FAILED';
      break;
    default:
      status = 'STARTING';
      break;
  }

  print(info.name);
  print('  Status: $status');
  print('  Absolute path: ${info.absolute}');

  if (info.closeReason != null) {
    print('\n  Close reason: ${info.closeReason}');
  }
}
