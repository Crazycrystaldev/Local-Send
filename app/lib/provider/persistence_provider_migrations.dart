part of 'persistence_provider.dart';

const _latestVersion = 2;

Future<void> _runMigrations(int from) async {
  switch (from) {
    case 1:
      await _migrate2();
      break;
  }
}

Future<void> _migrate2() async {
  _logger.info('Migrating to version 2');
  if (SharedPreferencesStorePlatform.instance is! SharedPreferencesPortable) {
    await enableContextMenu();

    if (defaultTargetPlatform == TargetPlatform.windows) {
      final newFolder = File(_windowsFile).parent;
      if (!newFolder.existsSync()) {
        newFolder.createSync(recursive: true);
      }

      final legacyFile = File(_windowsLegacyFile);
      legacyFile.copySync(_windowsFile);
      legacyFile.parent.parent.deleteSync(recursive: true);
      SharedPreferencesStorePlatform.instance = SharedPreferencesFile(filePath: _windowsFile);
      await SharedPreferencesStorePlatform.instance.setValue('Int', 'flutter.$_version', 2);
    }
  }
}
