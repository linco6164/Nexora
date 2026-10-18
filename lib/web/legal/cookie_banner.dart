import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_locale.dart';
import 'cookies_page.dart';

class CookieBanner extends StatefulWidget {
  const CookieBanner({super.key});

  @override
  State<CookieBanner> createState() => _CookieBannerState();
}

class _CookieBannerState extends State<CookieBanner> {
  static const _consentKey = 'nexora_cookie_consent';

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final hasConsentChoice = preferences.containsKey(_consentKey);
      if (mounted) {
        setState(() => _visible = !hasConsentChoice);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _visible = true);
      }
    }
  }

  Future<void> _saveConsent(String value) async {
    if (mounted) {
      setState(() => _visible = false);
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_consentKey, value);
    } catch (_) {
      // Banner-ul a fost deja inchis pentru sesiunea curenta.
    }
  }

  void _accept() {
    _saveConsent('accepted');
  }

  void _reject() {
    _saveConsent('rejected');
  }

  void _openPreferences() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            appLocaleController.value == 'en'
                ? 'Cookie preferences'
                : 'Preferințe cookie-uri',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            appLocaleController.value == 'en'
                ? 'Necessary cookies may be used to operate the platform. Optional cookies can only be enabled under applicable law.'
                : 'Cookie-urile necesare pot fi utilizate pentru funcționarea platformei. Cookie-urile opționale pot fi activate numai în condițiile prevăzute de legislația aplicabilă.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                appLocaleController.value == 'en' ? 'Close' : 'Închide',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _accept();
              },
              child: Text(
                appLocaleController.value == 'en' ? 'Accept' : 'Acceptă',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isNarrowScreen = mediaQuery.size.width < 820;
    final horizontalInset = mediaQuery.size.width < 600 ? 12.0 : 24.0;

    Widget cookieIcon({double size = 46}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(size < 46 ? 11 : 13),
        ),
        child: Icon(
          Icons.cookie_outlined,
          size: size < 46 ? 22 : 24,
          color: theme.colorScheme.primary,
        ),
      );
    }

    Widget title() {
      return Text(
        appLocaleController.value == 'en'
            ? 'We use cookies'
            : 'Folosim cookie-uri',
        style: TextStyle(
          fontSize: isNarrowScreen ? 15.5 : 16,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ),
      );
    }

    Widget description() {
      return Text(
        appLocaleController.value == 'en'
            ? 'Nexora uses cookies required for the platform to work and, based on your preferences, optional technologies.'
            : 'Nexora utilizează cookie-uri necesare pentru funcționarea platformei și, în funcție de preferințele tale, tehnologii opționale.',
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          color: theme.colorScheme.onSurface.withValues(alpha: .68),
        ),
      );
    }

    Widget policyLink() {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CookiesPage()));
          },
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            appLocaleController.value == 'en'
                ? 'View cookie policy'
                : 'Vezi Politica de cookie-uri',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    Widget actions({required bool compact}) {
      final rejectButton = OutlinedButton(
        onPressed: _reject,
        child: Text(appLocaleController.value == 'en' ? 'Reject' : 'Respinge'),
      );
      final preferencesButton = OutlinedButton.icon(
        onPressed: _openPreferences,
        icon: const Icon(Icons.tune_rounded, size: 17),
        label: Text(
          appLocaleController.value == 'en' ? 'Preferences' : 'Preferințe',
        ),
      );
      final acceptButton = FilledButton(
        onPressed: _accept,
        child: Text(appLocaleController.value == 'en' ? 'Accept' : 'Acceptă'),
      );

      if (!compact) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [rejectButton, preferencesButton, acceptButton],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: rejectButton),
              const SizedBox(width: 10),
              Expanded(child: acceptButton),
            ],
          ),
          const SizedBox(height: 9),
          preferencesButton,
        ],
      );
    }

    return Positioned(
      left: horizontalInset,
      right: horizontalInset,
      bottom: isNarrowScreen ? 8 : 24,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: isNarrowScreen ? 4 : 0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 1100,
              maxHeight: mediaQuery.size.height - mediaQuery.padding.top - 24,
            ),
            child: Material(
              elevation: 18,
              borderRadius: BorderRadius.circular(isNarrowScreen ? 18 : 20),
              clipBehavior: Clip.antiAlias,
              color: theme.colorScheme.surface,
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isNarrowScreen ? 16 : 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      isNarrowScreen ? 18 : 20,
                    ),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: .20),
                    ),
                  ),
                  child: isNarrowScreen
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                cookieIcon(size: 40),
                                const SizedBox(width: 12),
                                Expanded(child: title()),
                              ],
                            ),
                            const SizedBox(height: 12),
                            description(),
                            const SizedBox(height: 3),
                            policyLink(),
                            const SizedBox(height: 14),
                            actions(compact: true),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            cookieIcon(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  title(),
                                  const SizedBox(height: 5),
                                  description(),
                                  const SizedBox(height: 2),
                                  policyLink(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 390),
                              child: actions(compact: false),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
