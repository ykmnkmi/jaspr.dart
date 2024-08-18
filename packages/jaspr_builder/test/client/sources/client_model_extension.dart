import 'dart:convert';

import '../../codec/sources/model_extension.dart';
import 'client_model.dart';

final clientModelExtensionSources = {
  ...clientModelSources,
  ...modelExtensionSources,
  ...modelExtensionOutputs,
};

final clientModelExtensionJsonOutputs = {
  'site|lib/component_model.client.json': jsonEncode({
    "name": "Component",
    "id": ["site", "lib/component_model.dart"],
    "params": [
      {"name": "a", "isNamed": false, "decoder": "p.get('a')", "encoder": "c.a"},
      {
        "name": "b",
        "isNamed": true,
        "decoder": "[[package:site/model.dart]].ModelCodec.fromRaw(p.get('b'))",
        "encoder": "[[package:site/model.dart]].ModelCodec(c.b).toRaw()",
      },
    ]
  }),
};

final clientModelExtensionDartOutputs = {
  'site|web/component_model.client.dart': '// GENERATED FILE, DO NOT MODIFY\n'
      '// Generated with jaspr_builder\n'
      '\n'
      'import \'package:jaspr/browser.dart\';\n'
      'import \'package:site/component_model.dart\' as prefix0;\n'
      'import \'package:site/model.dart\' as prefix1;\n'
      '\n'
      'void main() {\n'
      '  runAppWithParams(getComponentForParams);\n'
      '}\n'
      '\n'
      'Component getComponentForParams(ConfigParams p) {\n'
      '  return prefix0.Component(p.get(\'a\'), b: prefix1.ModelCodec.fromRaw(p.get(\'b\')));\n'
      '}\n',
};
