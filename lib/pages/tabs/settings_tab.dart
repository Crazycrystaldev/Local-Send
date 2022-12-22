import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_app/gen/assets.gen.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/provider/network/server_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/version_provider.dart';
import 'package:localsend_app/theme.dart';
import 'package:localsend_app/widget/custom_dropdown_button.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final _aliasController = TextEditingController();
  final _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _aliasController.text = settings.alias;
    _portController.text = settings.port.toString();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final serverState = ref.watch(serverProvider);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 40),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(t.settings.title, style: Theme.of(context).textTheme.headline6, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 30),
        _SettingsSection(
          title: t.settings.general.title,
          children: [
            _SettingsEntry(
              label: t.settings.general.theme,
              child: CustomDropdownButton<ThemeMode>(
                value: settings.theme,
                items: ThemeMode.values.map((theme) {
                  return DropdownMenuItem(
                    value: theme,
                    alignment: Alignment.center,
                    child: Text(theme.humanName),
                  );
                }).toList(),
                onChanged: (theme) async {
                  if (theme != null) {
                    await ref.read(settingsProvider.notifier).setTheme(theme);
                  }
                },
              ),
            ),
            _SettingsEntry(
              label: t.settings.general.language,
              child: CustomDropdownButton<AppLocale?>(
                value: settings.locale,
                items: [
                  DropdownMenuItem(
                    value: null,
                    alignment: Alignment.center,
                    child: Text(t.settings.general.languageOptions.system),
                  ),
                  ...AppLocale.values.map((locale) {
                    return DropdownMenuItem(
                      value: locale,
                      alignment: Alignment.center,
                      child: Text(locale.humanName),
                    );
                  }),
                ],
                onChanged: (locale) async {
                  await ref.read(settingsProvider.notifier).setLocale(locale);
                  if (locale == null) {
                    LocaleSettings.useDeviceLocale();
                  } else {
                    LocaleSettings.setLocale(locale);
                  }
                },
              ),
            ),
          ],
        ),
        _SettingsSection(
          title: t.settings.network.title,
          children: [
            AnimatedCrossFade(
              crossFadeState: serverState != null && (serverState.alias != settings.alias || serverState.port != settings.port)
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topLeft,
              firstChild: Container(),
              secondChild: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(t.settings.network.needRestart, style: const TextStyle(fontSize: 16, color: Colors.orange)),
              ),
            ),
            _SettingsEntry(
              label: '${t.settings.network.server}${serverState == null ? ' (${t.general.offline})' : ''}',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: Theme.of(context).inputDecorationTheme.borderRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (serverState == null)
                      IconButton(
                        onPressed: () async {
                          await ref.read(serverProvider.notifier).startServer(
                                alias: settings.alias,
                                port: settings.port,
                              );
                        },
                        tooltip: t.receive.start,
                        icon: const Icon(Icons.play_arrow),
                      )
                    else
                      IconButton(
                        onPressed: () async {
                          final newServerState = await ref.read(serverProvider.notifier).restartServer(
                            alias: settings.alias,
                            port: settings.port,
                          );

                          if (newServerState != null) {
                            // the new state is always valid, so we can "repair" user's setting
                            _aliasController.text = newServerState.alias;
                            _portController.text = newServerState.port.toString();
                            await ref.read(settingsProvider.notifier).setAlias(newServerState.alias);
                            await ref.read(settingsProvider.notifier).setPort(newServerState.port);
                          }
                        },
                        tooltip: t.receive.restart,
                        icon: const Icon(Icons.refresh),
                      ),
                    IconButton(
                      onPressed: serverState == null
                          ? null
                          : () async {
                              await ref.read(serverProvider.notifier).stopServer();
                            },
                      tooltip: t.receive.stop,
                      icon: const Icon(Icons.stop),
                    ),
                  ],
                ),
              ),
            ),
            _SettingsEntry(
              label: t.settings.network.alias,
              child: TextFormField(
                controller: _aliasController,
                textAlign: TextAlign.center,
                onChanged: (s) async {
                  await ref.read(settingsProvider.notifier).setAlias(s);
                },
              ),
            ),
            _SettingsEntry(
              label: t.settings.network.port,
              child: TextFormField(
                controller: _portController,
                textAlign: TextAlign.center,
                onChanged: (s) async {
                  final port = int.tryParse(s);
                  if (port != null) {
                    await ref.read(settingsProvider.notifier).setPort(port);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Assets.img.logo512.image(
          width: 200,
          height: 200,
        ),
        const Text(
          'LocalSend',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        ref.watch(versionProvider).maybeWhen(
          data: (version) => Text(
            'Version: $version',
            textAlign: TextAlign.center,
          ),
          orElse: () => Container(),
        ),
        Text(
          '© ${DateTime.now().year} Tien Do Nam',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingsEntry({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          SizedBox(
            width: 150,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.subtitle1),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

extension on ThemeMode {
  String get humanName {
    switch (this) {
      case ThemeMode.system:
        return t.settings.general.themeOptions.system;
      case ThemeMode.light:
        return t.settings.general.themeOptions.light;
      case ThemeMode.dark:
        return t.settings.general.themeOptions.dark;
    }
  }
}

extension on AppLocale {
  String get humanName {
    switch (this) {
      case AppLocale.de:
        return 'Deutsch';
      case AppLocale.en:
        return 'English';
    }
  }
}
