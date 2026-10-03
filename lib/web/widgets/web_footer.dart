import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/responsive_container.dart';

import '../legal/about_page.dart';
import '../legal/delivery_page.dart';
import '../legal/privacy_page.dart';
import '../legal/terms_page.dart';
import '../legal/withdrawal_page.dart';
import '../legal/gdpr_page.dart';
import '../legal/cancellation_page.dart';
import '../legal/cookies_page.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  Widget _link(
    BuildContext context,
    String title, {
    Widget? page,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final action = onTap ??
        (page == null
            ? null
            : () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => page));
              });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: action,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
        letterSpacing: 0.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.20)),
        ),
      ),
      child: ResponsiveContainer(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BRAND
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Nexora',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: 330,
                        child: Text(
                          'Marketplace modern pentru '
                          'cumpărături și vânzări online.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.60,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'NEXORA STORE S.R.L.\n'
                        'CUI 51686427 • J2025029466000\n'
                        'Str. Argentina nr. 25, parter, Sector 1, București',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          _socialButton(context, Icons.facebook_rounded),
                          const SizedBox(width: 8),
                          _socialButton(context, Icons.camera_alt_outlined),
                          const SizedBox(width: 8),
                          _socialButton(context, Icons.alternate_email_rounded),
                        ],
                      ),
                    ],
                  ),
                ),

                // COMPANY
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Companie'),
                      const SizedBox(height: 14),

                      _link(
                        context,
                        'Date companie și rol',
                        page: const AboutPage(),
                      ),

                      _link(context, 'Cariere'),
                      _link(context, 'Presă'),
                      _link(context, 'Blog'),
                    ],
                  ),
                ),

                // SUPPORT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Suport'),
                      const SizedBox(height: 14),

                      _link(
                        context,
                        'Contact: contact@nx-store.com',
                        onTap: () async {
                          await launchUrl(
                            Uri.parse('mailto:contact@nx-store.com'),
                          );
                        },
                      ),

                      _link(context, 'Livrare', page: const DeliveryPage()),

                      _link(
                        context,
                        'Retur / retragere online',
                        page: const WithdrawalPage(),
                      ),

                      _link(
                        context,
                        'Anularea comenzilor',
                        page: const CancellationPage(),
                      ),
                    ],
                  ),
                ),

                // LEGAL
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Legal'),
                      const SizedBox(height: 14),

                      _link(
                        context,
                        'Politica de confidențialitate',
                        page: const PrivacyPage(),
                      ),

                      _link(
                        context,
                        'Termeni și condiții',
                        page: const TermsPage(),
                      ),

                      _link(
                        context,
                        'Dreptul de retragere',
                        page: const WithdrawalPage(),
                      ),

                      _link(context, 'GDPR', page: const GdprPage()),

                      _link(context, 'Cookies', page: const CookiesPage()),
                      _link(
                        context,
                        'ANPC',
                        onTap: () async {
                          await launchUrl(
                            Uri.parse('https://anpc.ro/'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            const SizedBox(height: 42),

            _buildPaymentMethods(context),

            const SizedBox(height: 42),

            Divider(
              color: theme.dividerColor.withValues(alpha: 0.20),
              height: 1,
            ),

            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© 2026 Nexora Store. Toate drepturile rezervate.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                  ),
                ),
                Text(
                  'Made with Nexora',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton(BuildContext context, IconData icon) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {},
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 19,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
          ),
        ),
      ),
    );
  }
}

Widget _buildPaymentMethods(BuildContext context) {
  final theme = Theme.of(context);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.18)),
    ),
    child: Row(
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 20,
          color: theme.colorScheme.primary,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plăți online securizate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Plățile cu cardul sunt procesate prin NETOPIA Payments.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(
            'assets/payments/netopia_payments_logo.png',
            width: 150,
            height: 72,
            fit: BoxFit.contain,
          ),
        ),
      ],
    ),
  );
}
