import 'package:build_runner/build_runner.dart';
import 'newline.dart';

final PhaseGroup phaseGroup = new PhaseGroup.singleAction(const NewlineFixer(),
    new InputSet('dartmonit', const ['lib/src/scripts/service.dart']));
