import 'package:flutter/material.dart';
import 'api_service.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await ApiService.getSessions();

      if (!mounted) return;

      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _deleteSession(
    String sessionId,
    String deviceName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Închizi sesiunea?'),
          content: Text(
            'Sesiunea de pe „$deviceName” va fi închisă.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Anulează'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Închide'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _deleting = true;
      });

      await ApiService.deleteSession(sessionId);

      await _loadSessions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesiunea a fost închisă.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  Future<void> _deleteOtherSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Închizi celelalte sesiuni?',
          ),
          content: const Text(
            'Toate celelalte dispozitive vor fi deconectate. '
            'Sesiunea de pe acest dispozitiv va rămâne activă.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Anulează'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Închide'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _deleting = true;
      });

      await ApiService.deleteOtherSessions();

      await _loadSessions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Celelalte sesiuni au fost închise.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Necunoscut';
    }

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      return '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Necunoscut';
    }
  }

  IconData _platformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'android':
        return Icons.phone_android_rounded;

      case 'ios':
        return Icons.phone_iphone_rounded;

      case 'windows':
        return Icons.laptop_windows_rounded;

      case 'macos':
        return Icons.laptop_mac_rounded;

      case 'web':
        return Icons.language_rounded;

      default:
        return Icons.devices_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesiuni și dispozitive'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: _sessions.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            'Nu există sesiuni active.',
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Dispozitive conectate',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Aici poți vedea și închide sesiunile active ale contului tău.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ..._sessions.map(
                          (session) => _buildSessionCard(
                            session,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (_sessions.any(
                          (session) =>
                              session['isCurrent'] != true,
                        ))
                          OutlinedButton(
                            onPressed: _deleting
                                ? null
                                : _deleteOtherSessions,
                            child: const Text(
                              'Închide toate celelalte sesiuni',
                            ),
                          ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildSessionCard(
    Map<String, dynamic> session,
  ) {
    final isCurrent =
        session['isCurrent'] == true;

    final deviceName =
        session['deviceName']?.toString() ??
            'Dispozitiv necunoscut';

    final platform =
        session['platform']?.toString() ??
            'unknown';

    final browser =
        session['browser']?.toString() ?? '';

    final ipAddress =
        session['ipAddress']?.toString() ?? '';

    final lastActive =
        _formatDate(session['lastActiveAt']);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                _platformIcon(platform),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          deviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      if (isCurrent)
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            borderRadius:
                                BorderRadius
                                    .circular(20),
                            color: Colors.green
                                .withValues(alpha: 0.12),
                          ),
                          child: const Text(
                            'Activ acum',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    platform,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  if (browser.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      browser,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],

                  if (ipAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'IP: $ipAddress',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  Text(
                    'Ultima activitate: $lastActive',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  if (!isCurrent) ...[
                    const SizedBox(height: 12),

                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _deleting
                            ? null
                            : () => _deleteSession(
                                  session['id']
                                      .toString(),
                                  deviceName,
                                ),
                        child: const Text(
                          'Închide sesiunea',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}