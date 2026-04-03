import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/schema.dart';

class ClientGenerator {
  Future<void> generate(
      List<ModelDefinition> models, String projectPath) async {
    print('📱 Generating Flutter Client API for $projectPath...');

    final clientDir = Directory(p.join(projectPath, 'lib/client'));
    if (!await clientDir.exists()) {
      await clientDir.create(recursive: true);
    }

    final clientFile = File(p.join(clientDir.path, 'api_client.dart'));
    final buffer = StringBuffer();

    buffer
        .writeln("import 'package:serverpod_flutter/serverpod_flutter.dart';");
    buffer.writeln();
    buffer.writeln("class ApiClient {");
    buffer.writeln("  late final dynamic client;");
    buffer.writeln();
    buffer.writeln("  ApiClient(String host) {");
    buffer.writeln("    // client = Client(host);");
    buffer.writeln("  }");
    buffer.writeln();
    buffer.writeln("  // Generated methods for models");
    for (final model in models) {
      final className = model.name;
      final varName = className.toLowerCase();
      buffer.writeln("  Future<List<dynamic>> get${className}s() async {");
      buffer.writeln("    // return await client.$varName.get${className}s();");
      buffer.writeln("    return [];");
      buffer.writeln("  }");
      buffer.writeln();
    }

    buffer.writeln("}");

    await clientFile.writeAsString(buffer.toString());
    print('✅ Client API generated in lib/client/api_client.dart');
  }
}
