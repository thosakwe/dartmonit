import 'dart:isolate';

main() {
  print('Hello');
  Isolate.current.kill();
}