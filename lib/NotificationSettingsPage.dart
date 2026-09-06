import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {
  bool _loading = true;
  bool _saving = false;

  bool push = true;
  bool messages = true;
  bool favorites = true;
  bool offers = true;
  bool account = true;
  bool sound = true;
  bool vibration = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings =
          await ApiService.getNotificationSettings();

      if (!mounted) return;

      setState(() {
        push = settings['push'] ?? true;
        messages = settings['messages'] ?? true;
        favorites = settings['favorites'] ?? true;
        offers = settings['offers'] ?? true;
        account = settings['account'] ?? true;
        sound = settings['sound'] ?? true;
        vibration = settings['vibration'] ?? true;

        _loading = false;
      });

      await _saveLocalCache();
    } catch (e) {
      // Dacă backend-ul nu este disponibil,
      // folosim valorile salvate local.
      await _loadLocalCache();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadLocalCache() async {
    final prefs = await SharedPreferences.getInstance();

    push = prefs.getBool('notifications_push') ?? true;
    messages =
        prefs.getBool('notifications_messages') ?? true;
    favorites =
        prefs.getBool('notifications_favorites') ?? true;
    offers =
        prefs.getBool('notifications_offers') ?? true;
    account =
        prefs.getBool('notifications_account') ?? true;
    sound =
        prefs.getBool('notifications_sound') ?? true;
    vibration =
        prefs.getBool('notifications_vibration') ?? true;
  }

  Future<void> _saveLocalCache() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notifications_push', push);
    await prefs.setBool(
      'notifications_messages',
      messages,
    );
    await prefs.setBool(
      'notifications_favorites',
      favorites,
    );
    await prefs.setBool(
      'notifications_offers',
      offers,
    );
    await prefs.setBool(
      'notifications_account',
      account,
    );
    await prefs.setBool(
      'notifications_sound',
      sound,
    );
    await prefs.setBool(
      'notifications_vibration',
      vibration,
    );
  }

  Future<void> _updateSetting(
    String key,
    bool value,
  ) async {
    if (_saving) return;

    setState(() {
      switch (key) {
        case 'push':
          push = value;
          break;
        case 'messages':
          messages = value;
          break;
        case 'favorites':
          favorites = value;
          break;
        case 'offers':
          offers = value;
          break;
        case 'account':
          account = value;
          break;
        case 'sound':
          sound = value;
          break;
        case 'vibration':
          vibration = value;
          break;
      }
    });

    await _saveLocalCache();

    setState(() {
      _saving = true;
    });

    try {
      await ApiService.updateNotificationSettings({
        key: value,
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('ApiException: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _settingTile({
    required String title,
    required String subtitle,
    required bool value,
    required String keyName,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: _saving
          ? null
          : (newValue) {
              _updateSetting(keyName, newValue);
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificări'),
      ),
      body: ListView(
        children: [
          _settingTile(
            title: 'Notificări push',
            subtitle:
                'Primește notificări de la Nexora',
            value: push,
            keyName: 'push',
          ),

          _settingTile(
            title: 'Mesaje',
            subtitle:
                'Primește notificări când primești mesaje noi',
            value: messages,
            keyName: 'messages',
          ),

          _settingTile(
            title: 'Favorite',
            subtitle:
                'Actualizări legate de produsele favorite',
            value: favorites,
            keyName: 'favorites',
          ),

          _settingTile(
            title: 'Oferte',
            subtitle:
                'Primește notificări despre oferte și activitate',
            value: offers,
            keyName: 'offers',
          ),

          _settingTile(
            title: 'Activitatea contului',
            subtitle:
                'Securitate și activitate importantă a contului',
            value: account,
            keyName: 'account',
          ),

          const Divider(),

          _settingTile(
            title: 'Sunet',
            subtitle:
                'Redă un sunet pentru notificări',
            value: sound,
            keyName: 'sound',
          ),

          _settingTile(
            title: 'Vibrații',
            subtitle:
                'Vibrează telefonul la primirea notificărilor',
            value: vibration,
            keyName: 'vibration',
          ),
        ],
      ),
    );
  }
}