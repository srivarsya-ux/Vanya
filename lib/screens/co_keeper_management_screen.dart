import 'package:flutter/material.dart';
import '../widgets/vanya_expression.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../backend/oneir_identity.dart';
import '../backend/co_keeper_backend.dart';

/// The "seamless connection" management screen -- shows the current
/// Co-Keeper status and lets the user invite one, or remove the existing
/// one. Removal uses a 24-hour delayed effect per the Co-Keeper philosophy
/// doc (cancellable), rather than disconnecting instantly.
class CoKeeperManagementScreen extends StatefulWidget {
  const CoKeeperManagementScreen({super.key});

  @override
  State<CoKeeperManagementScreen> createState() => _CoKeeperManagementScreenState();
}

class _CoKeeperManagementScreenState extends State<CoKeeperManagementScreen> {
  String? _pairedId;
  bool _loading = true;
  bool _removalPending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await OneirIdentity.getPairedCoKeeperId();
    if (!mounted) return;
    setState(() {
      _pairedId = id;
      _loading = false;
    });
  }

  Future<void> _confirmRemoval() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OneirColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OneirRadius.lg)),
        title: Text('Remove Co-Keeper?', style: OneirText.title),
        content: Text(
          'This takes effect in 24 hours, and protected apps will be unlocked once it does. '
          'You can cancel any time before then.',
          style: OneirText.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: OneirText.bodyStrong.copyWith(color: OneirColors.textMuted))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _removalPending = true);
      // NOTE: the actual 24-hour delayed-effect timer isn't implemented yet
      // (needs a scheduled background task, e.g. WorkManager on Android) --
      // this only reflects the *intent* in the UI for now.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneirColors.background,
      appBar: AppBar(
        backgroundColor: OneirColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OneirColors.text), onPressed: () => Navigator.of(context).pop()),
        title: Text('Co-Keepers', style: OneirText.title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OneirColors.accent))
          : Padding(
              padding: const EdgeInsets.all(OneirSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pairedId == null) ...[
                    const VanyaCharacter(expression: VanyaExpression.protecting, width: 180, height: 180),
                    const SizedBox(height: OneirSpace.xxl - 4),
                    Text('No Co-Keeper yet', style: OneirText.heading.copyWith(fontSize: 20)),
                    const SizedBox(height: OneirSpace.sm),
                    Text(
                      "You haven't connected a Co-Keeper. Add one from onboarding, or invite someone now.",
                      style: OneirText.body,
                    ),
                  ] else ...[
                    OneirCard(
                      padding: const EdgeInsets.all(OneirSpace.lg),
                      color: OneirColors.surfaceSunken,
                      elevated: false,
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: const BoxDecoration(color: OneirColors.surface, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const Icon(Icons.check_circle, color: OneirColors.accentStrong),
                          ),
                          const SizedBox(width: OneirSpace.md + 2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_removalPending ? 'Removal pending' : 'Connected', style: OneirText.bodyStrong),
                                Text(
                                  _removalPending ? 'Access restores automatically in 24 hours.' : 'Your Co-Keeper is holding your key.',
                                  style: OneirText.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: OneirSpace.xl),
                    if (!_removalPending)
                      OneirSecondaryButton(label: 'Remove Co-Keeper', onPressed: _confirmRemoval)
                    else
                      OneirSecondaryButton(label: 'Cancel Removal', onPressed: () => setState(() => _removalPending = false)),
                  ],
                  const SizedBox(height: OneirSpace.xxl),
                  Text('Recent approvals', style: OneirText.bodyStrong),
                  const SizedBox(height: OneirSpace.sm),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: CoKeeperBackend.watchPendingRequestsForMe(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Text(
                        count == 0 ? 'Nothing pending right now.' : '$count request${count == 1 ? '' : 's'} waiting on you.',
                        style: OneirText.bodySmall,
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
