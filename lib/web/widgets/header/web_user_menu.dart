import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../dialogs/login_dialog.dart';

class WebUserMenu extends StatelessWidget {
  const WebUserMenu({super.key});

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
                child: const Text("Login"),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const LoginDialog(),
                  );
                },
                child: const Text("Register"),
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
            switch (value) {
              case "profile":
                break;

              case "listings":
                break;

              case "favorites":
                break;

              case "messages":
                break;

              case "orders":
                break;

              case "settings":
                break;

              case "logout":
                await auth.logout();
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: "profile", child: Text("Profile")),
            PopupMenuItem(value: "listings", child: Text("My Listings")),
            PopupMenuItem(value: "favorites", child: Text("Favorites")),
            PopupMenuItem(value: "messages", child: Text("Messages")),
            PopupMenuItem(value: "orders", child: Text("Orders")),
            PopupMenuItem(value: "settings", child: Text("Settings")),
            PopupMenuDivider(),
            PopupMenuItem(value: "logout", child: Text("Logout")),
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
