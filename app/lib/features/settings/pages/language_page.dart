import 'package:acter/common/utils/language.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/model/language_model.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: _buildAppbar(),
        body: _buildBody(ref),
      ),
    );
  }

  AppBar _buildAppbar() {
    return AppBar(
      backgroundColor: const AppBarTheme().backgroundColor,
      elevation: 0.0,
      title: const Text('Language'),
      centerTitle: true,
    );
  }

  Widget _buildBody(WidgetRef ref) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: LanguageModel.allLanguagesList.length,
      itemBuilder: (context, index) {
        final language = LanguageModel.allLanguagesList[index];
        return _languageItem(ref, language);
      },
    );
  }

  Widget _languageItem(WidgetRef ref, LanguageModel language) {
    return Card(
      child: RadioListTile(
        value: language.languageCode,
        groupValue: ref.watch(languageProvider),
        title: Text(language.languageName),
        onChanged: (value) async {
          if (value != null) {
            await setLanguage(value);
            ref.read(languageProvider.notifier).update((state) => value);
          }
        },
      ),
    );
  }
}
