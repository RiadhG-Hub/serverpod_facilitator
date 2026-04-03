

import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/schema.dart';

class AuthGenerator {
  Future<void> generate(List<ModelDefinition> models, String projectPath) async {
    print('🔐 Generating Authentication system for $projectPath...');
    
    final endpointsDir = Directory(p.join(projectPath, 'lib/endpoints'));
    if (!await endpointsDir.exists()) {
      await endpointsDir.create(recursive: true);
    }

    final authEndpoint = File(p.join(endpointsDir.path, 'auth_endpoint.dart'));
    await authEndpoint.writeAsString('''
import 'package:serverpod/serverpod.dart';
import '../models/user.dart';

class AuthEndpoint extends Endpoint {
  Future<String?> login(Session session, String email, String password) async {
    // Prototype: In a real system, verify password hash
    final user = await User.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );
    
    if (user != null) {
      // Generate JWT (simplified)
      return 'fake-jwt-token-for-\${user.id}';
    }
    return null;
  }

  Future<bool> register(Session session, String email, String password, String name) async {
    final user = User(
      email: email,
      name: name,
      createdAt: DateTime.now(),
    );
    await User.db.insertRow(session, user);
    return true;
  }
}
''');

    print('✅ Auth system generated in lib/endpoints/auth_endpoint.dart');
  }
}
