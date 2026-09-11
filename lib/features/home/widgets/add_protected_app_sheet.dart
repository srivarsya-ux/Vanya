import 'package:flutter/material.dart';

import '../../../models/protected_app.dart';
import '../../../native/vanya_permissions.dart';

/// Picks an installed app to protect, reusing the same native
/// `listInstalledApps` channel the onboarding protected-apps screen
/// already uses — no reason to duplicate that platform code here.
class AddProtectedAppSheet extends StatefulWidget {
  const AddProtectedAppSheet({super.key, required this.alreadyProtected});

  final Set<String> alreadyProtected;

  static Future<ProtectedApp?> show(
    BuildContext context, {
    required Set<String> alreadyProtected,
  }) {
    return showModalBottomSheet<ProtectedApp>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddProtectedAppSheet(alreadyProtected: alreadyProtected),
    );
  }

  @override
  State<AddProtectedAppSheet> createState() => _AddProtectedAppSheetState();
}

class _AddProtectedAppSheetState extends State<AddProtectedAppSheet> {
  List<InstalledApp>? _apps;
  String? _error;

  @override
  void initState() {
    super.initState();
    VanyaPermissions.listInstalledApps().then((apps) {
      if (!mounted) return;
      setState(() => _apps = apps);
    }).catchError((e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        if (_error != null) {
          return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Could not load apps: $_error')));
        }
        final apps = _apps;
        if (apps == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final selectable = apps.where((a) => !widget.alreadyProtected.contains(a.packageName)).toList();
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: selectable.length,
          itemBuilder: (context, index) {
            final app = selectable[index];
            return ListTile(
              title: Text(app.label),
              subtitle: Text(app.packageName, style: const TextStyle(fontSize: 11)),
              onTap: () => Navigator.of(context).pop(
                ProtectedApp(packageName: app.packageName, displayName: app.label),
              ),
            );
          },
        );
      },
    );
  }
}
