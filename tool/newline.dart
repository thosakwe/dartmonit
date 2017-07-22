import 'dart:async';
import 'package:build/build.dart';

class NewlineFixer implements Builder {
  const NewlineFixer();

  @override
  Future build(BuildStep buildStep) async {
    var contents = await buildStep.readAsString(buildStep.inputId);
    var newlinesFixed = contents.replaceAll('\r\n', '\n');
    buildStep.writeAsString(
        buildStep.inputId.changeExtension('.g.dart'), newlinesFixed);
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      '.dart': ['.g.dart']
    };
  }
}
