import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/init.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/theme.dart';
import 'package:localsend_app/util/device_info_helper.dart';
import 'package:routerino/routerino.dart';

Future<void> main() async {
  final persistenceService = await preInit();
  runApp(TranslationProvider(
    child: ProviderScope(
      overrides: [
        deviceRawInfoProvider.overrideWithValue(await getDeviceInfo()),
        persistenceProvider.overrideWithValue(persistenceService),
      ],
      child: const LocalSendApp(),
    ),
  ));
}

class LocalSendApp extends ConsumerWidget {
  const LocalSendApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((settings) => settings.theme));
    return MaterialApp(
      title: t.appName,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: LocaleSettings.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: getTheme(Brightness.light),
      darkTheme: getTheme(Brightness.dark),
      themeMode: themeMode,
      navigatorKey: Routerino.navigatorKey,
      home: const HomePage(),
    );
  }
}
