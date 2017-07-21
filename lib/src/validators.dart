import 'package:angel_validate/angel_validate.dart';

final Validator spawnProcess = new Validator({
  'path*': isNonEmptyString,
  'args': isNonEmptyString,
  'concurrency': [isInt, isPositive]
});
