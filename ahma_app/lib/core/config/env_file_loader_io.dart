import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<Map<String, String>> loadLocalEnvFile() async {
  final candidates = <File>[
    File('.env'),
    File('ahma_app/.env'),
    ..._ancestorEnvFiles(Directory.current),
    ..._ancestorEnvFiles(File(Platform.resolvedExecutable).parent),
  ];

  final seen = <String>{};

  for (final file in candidates) {
    final normalizedPath = file.absolute.path;
    if (!seen.add(normalizedPath)) {
      continue;
    }

    try {
      if (await file.exists()) {
        final lines = await file.readAsLines();
        print('[Env] Loaded local environment from $normalizedPath');
        return const Parser().parse(lines);
      }
    } on FileSystemException catch (e) {
      print(
        '[Env] Cannot read $normalizedPath: ${e.osError?.message ?? e.message}',
      );
    }
  }

  print('[Env] No local .env file found; using bundled .env.example fallback');
  return {};
}

Iterable<File> _ancestorEnvFiles(Directory start) sync* {
  var directory = start.absolute;

  while (true) {
    yield File('${directory.path}/.env');
    yield File('${directory.path}/ahma_app/.env');

    final parent = directory.parent;
    if (parent.path == directory.path) {
      break;
    }

    directory = parent;
  }
}
