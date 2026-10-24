import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/infrastructure/db/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});
