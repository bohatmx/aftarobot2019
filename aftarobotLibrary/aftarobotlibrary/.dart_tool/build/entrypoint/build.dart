import 'package:build_runner_core/build_runner_core.dart' as _i1;
import 'package:source_gen/builder.dart' as _i2;
import 'package:simple_auth_generator/simple_auth_generator.dart' as _i3;
import 'package:build_config/build_config.dart' as _i4;
import 'dart:isolate' as _i5;
import 'package:build_runner/build_runner.dart' as _i6;

final _builders = <_i1.BuilderApplication>[
  _i1.apply('source_gen|combining_builder', [_i2.combiningBuilder],
      _i1.toNoneByDefault(),
      hideOutput: false, appliesBuilders: ['source_gen|part_cleanup']),
  _i1.apply('simple_auth_generator|simple_auth_generator',
      [_i3.simple_authGeneratorFactory], _i1.toRoot(),
      hideOutput: false),
  _i1.applyPostProcess('source_gen|part_cleanup', _i2.partCleanup,
      defaultGenerateFor: const _i4.InputSet())
];
main(List<String> args, [_i5.SendPort sendPort]) async {
  var result = await _i6.run(args, _builders);
  sendPort?.send(result);
}
