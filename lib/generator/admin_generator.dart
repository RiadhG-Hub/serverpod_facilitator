

import 'dart:io';

import 'package:path/path.dart' as p;
import '../models/schema.dart';

class AdminGenerator {
  Future<void> generate(
      List<ModelDefinition> models, String projectPath) async {
    print('📊 Generating Flutter Admin Panel for $projectPath...');

    final adminDir = Directory(p.join(projectPath, 'flutter_admin'));
    if (!await adminDir.exists()) {
      await adminDir.create(recursive: true);
    }

    // Create a simple Flutter dashboard with CRUD for models
    final mainFile = File(p.join(adminDir.path, 'lib/main.dart'));
    final libDir = Directory(p.join(adminDir.path, 'lib'));
    if (!await libDir.exists()) {
      await libDir.create(recursive: true);
    }

    await mainFile.writeAsString('''
import 'package:flutter/material.dart';

void main() {
  runApp(AdminApp());
}

class AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serverpod Facilitator Admin',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Dashboard(),
    );
  }
}

class Dashboard extends StatelessWidget {
  final List<String> models = [${models.map((m) => "'${m.name}'").join(', ')}];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: ListView.builder(
        itemCount: models.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(models[index]),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to CRUD for this model
            },
          );
        },
      ),
    );
  }
}
''');

    print('✅ Admin panel generated in flutter_admin/');
  }
}
