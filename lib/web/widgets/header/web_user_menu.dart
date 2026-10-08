import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../dialogs/login_dialog.dart';
import '../../dialogs/register_dialog.dart';

class WebUserMenu extends StatelessWidget {
  final ValueChanged<String>? onNavigate;

  const WebUserMenu({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // =========================
        // NOT LOGGED IN
        // =========================
        if (!auth.isLoggedIn) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const LoginDialog(),
                  );
                },
                child: const Text("Autentificare"),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const RegisterDialog(),
                  );
                },
                child: const Text("Înregistrare"),
              ),
            ],
          );
        }

        // =========================
        // LOGGED IN
        // =========================

        final user = auth.user!;

        final avatar = user["avatar"]?.toString() ?? "";
        final username = user["username"]?.toString() ?? "User";

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          onSelected: (value) async {
            if (value == "logout") {
              await auth.logout();
            } else {
              onNavigate?.call(value);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: "profile",
              enabled: onNavigate != null,
              child: const Text("Profil"),
            ),
            PopupMenuItem(
              value: "listings",
              enabled: onNavigate != null,
              child: const Text("Anunțurile mele"),
            ),
            PopupMenuItem(
              value: "favorites",
              enabled: onNavigate != null,
              child: const Text("Favorite"),
            ),
            PopupMenuItem(
              value: "messages",
              enabled: onNavigate != null,
              child: const Text("Mesaje"),
            ),
            PopupMenuItem(
              value: "orders",
              enabled: onNavigate != null,
              child: const Text("Comenzi"),
            ),
            PopupMenuItem(
              value: "settings",
              enabled: onNavigate != null,
              child: const Text("Setări"),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: "logout", child: Text("Deconectare")),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 10),
              Text(
                username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        );
      },
    );
  }
}
