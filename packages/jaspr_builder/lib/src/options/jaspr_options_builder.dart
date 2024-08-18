import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import '../client/client_module_builder.dart';
import '../styles/styles_module_builder.dart';
import '../utils.dart';

/// Builds part files and web entrypoints for components annotated with @app
class JasprOptionsBuilder implements Builder {
  JasprOptionsBuilder(BuilderOptions options);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    try {
      await generateOptionsOutput(buildStep);
    } catch (e, st) {
      print('An unexpected error occurred.\n'
          'This is probably a bug in jaspr_builder.\n'
          'Please report this here: '
          'https://github.com/schultek/jaspr/issues\n\n'
          'The error was:\n$e\n\n$st');
      rethrow;
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        r'lib/$lib$': ['lib/jaspr_options.dart'],
      };

  String get generationHeader => "// GENERATED FILE, DO NOT MODIFY\n"
      "// Generated with jaspr_builder\n";

  Future<void> generateOptionsOutput(BuildStep buildStep) async {
    final pubspecYaml = await buildStep.readAsString(AssetId(buildStep.inputId.package, 'pubspec.yaml'));
    final mode = yaml.loadYaml(pubspecYaml)?['jaspr']?['mode'];

    if (mode != 'static' && mode != 'server') {
      return;
    }

    final clients = await loadClientModules(buildStep);
    final styles = await loadStylesModules(buildStep);

    clients.sortByCompare((c) => '${c.id.toImportUrl()}/${c.name}', ImportsWriter.compareImports);
    clients.sortByCompare((s) => s.id.toImportUrl(), ImportsWriter.compareImports);

    var source = '''
      $generationHeader
      
      import 'package:jaspr/jaspr.dart';
      [[/]]
      
      /// Default [JasprOptions] for use with your jaspr project.
      ///
      /// Use this to initialize jaspr **before** calling [runApp].
      ///
      /// Example:
      /// ```dart
      /// import 'jaspr_options.dart';
      /// 
      /// void main() {
      ///   Jaspr.initializeApp(
      ///     options: defaultJasprOptions,
      ///   );
      ///   
      ///   runApp(...);
      /// }
      /// ```
      final defaultJasprOptions = JasprOptions(
        ${buildClientEntries(clients)}
        ${buildStylesEntries(styles)}
      );
      
      ${buildClientParamGetters(clients)}  
    ''';
    source = ImportsWriter().resolve(source);
    source = DartFormatter(pageWidth: 120).format(source);

    final optionsId = AssetId(buildStep.inputId.package, 'lib/jaspr_options.dart');
    await buildStep.writeAsString(optionsId, source);
  }

  Future<List<ClientModule>> loadClientModules(BuildStep buildStep) {
    return buildStep
        .findAssets(Glob('lib/**.client.json'))
        .asyncMap((id) => buildStep.readAsString(id))
        .map((c) => ClientModule.deserialize(jsonDecode(c)))
        .toList();
  }

  Future<List<StylesModule>> loadStylesModules(BuildStep buildStep) {
    return buildStep
        .findAssets(Glob('lib/**.styles.json'))
        .asyncMap((id) => buildStep.readAsString(id))
        .map((c) => StylesModule.deserialize(jsonDecode(c)))
        .toList();
  }

  String buildClientEntries(List<ClientModule> clients) {
    if (clients.isEmpty) return '';
    return 'clients: {${clients.map((c) {
      return '''
        [[${c.id.toImportUrl()}]].${c.name}: ClientTarget<[[${c.id.toImportUrl()}]].${c.name}>(
          '${path.url.relative(path.url.withoutExtension(c.id.path), from: 'lib')}'
          ${c.params.isNotEmpty ? ', params: _[[${c.id.toImportUrl()}]]${c.name}' : ''}
        ),
      ''';
    }).join('\n')}},';
  }

  String buildClientParamGetters(List<ClientModule> clients) {
    return clients.where((c) => c.params.isNotEmpty).map((c) {
      return 'Map<String, dynamic> _[[${c.id.toImportUrl()}]]${c.name}([[${c.id.toImportUrl()}]].${c.name} c) => {${c.params.map((p) => "'${p.name}': ${p.encoder}").join(', ')}};';
    }).join('\n');
  }

  String buildStylesEntries(List<StylesModule> styles) {
    if (styles.isEmpty) return '';

    return 'styles: () => [${styles.map((s) {
      return s.elements.map((e) => '...[[${s.id.toImportUrl()}]].$e,').join('\n');
    }).join('\n')}],';
  }
}
