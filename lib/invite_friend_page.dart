import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'api_service.dart';
import 'app_feedback.dart';
import 'web/widgets/web_page_frame.dart';

class InviteFriendPage extends StatefulWidget {
  const InviteFriendPage({super.key});

  @override
  State<InviteFriendPage> createState() => _InviteFriendPageState();
}

class _InviteFriendPageState extends State<InviteFriendPage> {
  late Future<Map<String, dynamic>> _referralFuture;

  @override
  void initState() {
    super.initState();
    _referralFuture = ApiService.getReferralInfo();
  }

  Future<void> _refresh() async {
    final future = ApiService.getReferralInfo();
    setState(() => _referralFuture = future);
    await future;
  }

  void _retry() {
    setState(() => _referralFuture = ApiService.getReferralInfo());
  }

  Future<void> _copy(String value, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    AppFeedback.success(context, confirmation);
  }

  Future<void> _share(String code, String inviteUrl) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Invitație Nexora',
          text:
              'Te invit pe Nexora Store. După ce publici 2 anunțuri și finalizezi o vânzare, primim amândoi câte 100 RON. Folosește codul $code: $inviteUrl',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        error,
        fallback: 'Invitația nu a putut fi distribuită.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = FutureBuilder<Map<String, dynamic>>(
      future: _referralFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _InviteError(error: snapshot.error, onRetry: _retry);
        }

        return _InviteContent(
          data: snapshot.data!,
          onCopy: _copy,
          onShare: _share,
          onRefresh: _refresh,
        );
      },
    );

    if (kIsWeb) {
      return Scaffold(
        body: WebPageFrame(
          title: 'Invită un prieten',
          subtitle: 'Trimite linkul tău personal și urmărește invitațiile.',
          maxWidth: 820,
          useSurface: false,
          actions: [
            IconButton.filledTonal(
              tooltip: 'Înapoi',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ],
          child: content,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Invită un prieten')),
      body: SafeArea(child: content),
    );
  }
}

class _InviteContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<void> Function(String value, String confirmation) onCopy;
  final Future<void> Function(String code, String inviteUrl) onShare;
  final Future<void> Function() onRefresh;

  const _InviteContent({
    required this.data,
    required this.onCopy,
    required this.onShare,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final code = data['code']?.toString() ?? '';
    final inviteUrl = data['inviteUrl']?.toString() ?? '';
    final totalInvited = (data['totalInvited'] as num?)?.toInt() ?? 0;
    final program = data['program'] is Map
        ? Map<String, dynamic>.from(data['program'] as Map)
        : const <String, dynamic>{};
    final rewardAmount = (program['rewardAmount'] as num?)?.toInt() ?? 100;
    final myProgress = data['myProgress'] is Map
        ? Map<String, dynamic>.from(data['myProgress'] as Map)
        : null;
    final rawInvites = data['recentInvites'];
    final recentInvites = rawInvites is List
        ? rawInvites
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    final body = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, kIsWeb ? 0 : 18, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primaryContainer,
                colors.tertiaryContainer.withValues(alpha: .72),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: colors.surface.withValues(alpha: .88),
                child: Icon(
                  Icons.group_add_rounded,
                  size: 32,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Primiți amândoi câte $rewardAmount RON',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Prietenul invitat publică 2 anunțuri și finalizează o vânzare. Bonusul intră automat în soldul fiecăruia.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (myProgress != null) ...[
          _ReferralProgressCard(progress: myProgress),
          const SizedBox(height: 16),
        ],
        _InviteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Codul tău personal',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      code,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Copiază codul',
                    onPressed: code.isEmpty
                        ? null
                        : () => onCopy(code, 'Codul invitației a fost copiat.'),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 20, color: colors.primary),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        inviteUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copiază linkul',
                      visualDensity: VisualDensity.compact,
                      onPressed: inviteUrl.isEmpty
                          ? null
                          : () => onCopy(
                              inviteUrl,
                              'Linkul invitației a fost copiat.',
                            ),
                      icon: const Icon(Icons.content_copy_rounded, size: 19),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: code.isEmpty || inviteUrl.isEmpty
                    ? null
                    : () => onShare(code, inviteUrl),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Trimite invitația'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InviteCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.people_alt_outlined, color: colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalInvited',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      totalInvited == 1
                          ? 'prieten s-a înregistrat'
                          : 'prieteni s-au înregistrat',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (recentInvites.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            'Invitații recente',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _InviteCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < recentInvites.length; index++) ...[
                  _RecentInvite(invite: recentInvites[index]),
                  if (index != recentInvites.length - 1)
                    const Divider(height: 1, indent: 68),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        Text(
          'Cum funcționează',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const _InviteStep(
          number: '1',
          title: 'Distribuie linkul',
          description: 'Trimite invitația prin aplicația preferată.',
        ),
        const _InviteStep(
          number: '2',
          title: 'Prietenul publică 2 anunțuri',
          description: 'Sunt luate în calcul anunțurile publicate după crearea contului din invitație.',
        ),
        const _InviteStep(
          number: '3',
          title: 'Finalizează o vânzare',
          description: 'Una dintre comenzile pentru anunțurile eligibile trebuie să ajungă la starea finalizată.',
        ),
        _InviteStep(
          number: '4',
          title: 'Primiți bonusul',
          description:
              'Câte $rewardAmount RON sunt adăugați automat în soldul fiecăruia.',
        ),
        const SizedBox(height: 8),
        Text(
          'Bonusul se acordă o singură dată pentru fiecare invitație eligibilă, după finalizarea vânzării. Conturile sau tranzacțiile frauduloase nu sunt eligibile.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
        ),
      ],
    );

    return RefreshIndicator(onRefresh: onRefresh, child: body);
  }
}

class _InviteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _InviteCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .7)),
      ),
      child: child,
    );
  }
}

class _ReferralProgressCard extends StatelessWidget {
  final Map<String, dynamic> progress;

  const _ReferralProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final listings = (progress['listingsPublished'] as num?)?.toInt() ?? 0;
    final listingsRequired =
        (progress['listingsRequired'] as num?)?.toInt() ?? 2;
    final completedSales = (progress['completedSales'] as num?)?.toInt() ?? 0;
    final salesRequired =
        (progress['completedSalesRequired'] as num?)?.toInt() ?? 1;
    final rewardAmount = (progress['rewardAmount'] as num?)?.toInt() ?? 100;
    final rewarded = progress['rewardGranted'] == true;

    return _InviteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                rewarded
                    ? Icons.celebration_rounded
                    : Icons.track_changes_rounded,
                color: colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rewarded ? 'Bonus primit' : 'Progresul bonusului tău',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (rewarded)
                Text(
                  '+$rewardAmount RON',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _ProgressRequirement(
            complete: listings >= listingsRequired,
            title: 'Anunțuri publicate',
            value: '${listings.clamp(0, listingsRequired)}/$listingsRequired',
          ),
          const SizedBox(height: 10),
          _ProgressRequirement(
            complete: completedSales >= salesRequired,
            title: 'Vânzare finalizată',
            value: '${completedSales.clamp(0, salesRequired)}/$salesRequired',
          ),
          if (!rewarded) ...[
            const SizedBox(height: 13),
            Text(
              'După îndeplinirea ambelor condiții, tu și persoana care te-a invitat primiți automat câte $rewardAmount RON.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressRequirement extends StatelessWidget {
  final bool complete;
  final String title;
  final String value;

  const _ProgressRequirement({
    required this.complete,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          complete
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 21,
          color: complete ? colors.primary : colors.outline,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: complete ? colors.primary : colors.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InviteStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _InviteStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primaryContainer,
            child: Text(
              number,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentInvite extends StatelessWidget {
  final Map<String, dynamic> invite;

  const _RecentInvite({required this.invite});

  String _dateLabel(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Cont creat';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final username = invite['username']?.toString().trim();
    final displayName = username?.isNotEmpty == true ? username! : 'Utilizator';
    final avatar = invite['avatar']?.toString().trim();
    final progress = invite['progress'] is Map
        ? Map<String, dynamic>.from(invite['progress'] as Map)
        : const <String, dynamic>{};
    final listings = (progress['listingsPublished'] as num?)?.toInt() ?? 0;
    final listingsRequired =
        (progress['listingsRequired'] as num?)?.toInt() ?? 2;
    final completedSales = (progress['completedSales'] as num?)?.toInt() ?? 0;
    final rewarded = progress['rewardGranted'] == true;
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundImage: avatar?.isNotEmpty == true
            ? NetworkImage(avatar!)
            : null,
        child: avatar?.isNotEmpty == true
            ? null
            : Text(displayName.substring(0, 1).toUpperCase()),
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('S-a alăturat la ${_dateLabel(invite['joinedAt'])}'),
          const SizedBox(height: 3),
          Text(
            rewarded
                ? 'Bonus acordat'
                : '${listings.clamp(0, listingsRequired)}/$listingsRequired anunțuri • ${completedSales > 0 ? 'vânzare finalizată' : 'vânzare în așteptare'}',
            style: TextStyle(
              color: rewarded ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      trailing: Icon(
        rewarded ? Icons.card_giftcard_rounded : Icons.timelapse_rounded,
        color: rewarded ? colors.primary : colors.outline,
      ),
    );
  }
}

class _InviteError extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _InviteError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_rounded, size: 52),
            const SizedBox(height: 14),
            Text(
              AppFeedback.readableError(
                error ?? '',
                fallback: 'Invitația nu a putut fi încărcată.',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reîncearcă'),
            ),
          ],
        ),
      ),
    );
  }
}
