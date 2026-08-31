import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../backend/co_keeper_backend.dart';

/// Lives on the Co-Keeper's own device/install of Oneir. Shows any pending
/// "can I open this app?" requests from the person who paired them as a
/// Co-Keeper, in real time (Firestore stream), with one-tap Approve/Decline
/// -- this is the "one-tap approval" model from the Co-Keeper philosophy
/// doc, replacing typed/shared unlock codes.
class CoKeeperInboxScreen extends StatelessWidget {
  const CoKeeperInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneirColors.background,
      appBar: AppBar(
        backgroundColor: OneirColors.background,
        elevation: 0,
        title: Text('Co-Keeper requests', style: OneirText.title),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: CoKeeperBackend.watchPendingRequestsForMe(),
        builder: (context, snapshot) {
          // This used to spin forever with no way out whenever the stream
          // never emitted -- most commonly because Firebase isn't
          // configured yet on this build (see main.dart's
          // Firebase.initializeApp() catch block and SETUP.md section 4),
          // in which case Firestore calls here just never resolve. An
          // honest message beats an infinite spinner either way, whether
          // the real cause is that or something else.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(OneirSpace.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 28, color: OneirColors.textFaint),
                    const SizedBox(height: OneirSpace.md),
                    Text(
                      "Couldn't load Co-Keeper requests. This usually means Oneir's backend isn't set up yet on this build (see SETUP.md).",
                      textAlign: TextAlign.center,
                      style: OneirText.bodySmall.copyWith(color: OneirColors.textFaint),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: OneirColors.accent));
          }
          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return Center(
              child: Text('No pending requests', style: OneirText.bodySmall.copyWith(color: OneirColors.textFaint)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(OneirSpace.xl),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: OneirSpace.md),
            itemBuilder: (context, i) => _RequestCard(request: requests[i]),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  const _RequestCard({required this.request});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _responding = false;

  Future<void> _respond(bool approved) async {
    setState(() => _responding = true);
    await CoKeeperBackend.respondToRequest(widget.request['id'] as String, approved: approved);
    // No need to reset _responding -- the stream removes this card once its
    // status is no longer "pending".
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.request['requesterName'] as String? ?? 'Someone';
    final appPackage = widget.request['appPackage'] as String? ?? 'an app';
    final reason = widget.request['reason'] as String? ?? '';
    final duration = widget.request['durationMinutes'] as int? ?? 15;

    return OneirCard(
      padding: const EdgeInsets.all(OneirSpace.lg + 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$name wants to unlock $appPackage', style: OneirText.bodyStrong),
        if (reason.isNotEmpty) ...[
          const SizedBox(height: OneirSpace.xs + 2),
          Text('Reason: $reason', style: OneirText.bodySmall),
        ],
        const SizedBox(height: OneirSpace.xs + 2),
        Text('Requesting $duration minutes', style: OneirText.caption),
        const SizedBox(height: OneirSpace.md + 2),
        if (_responding)
          const Center(child: CircularProgressIndicator(color: OneirColors.accent))
        else
          Row(children: [
            Expanded(child: OneirPrimaryButton(label: 'Approve', onPressed: () => _respond(true))),
            const SizedBox(width: OneirSpace.sm + 2),
            Expanded(child: OneirSecondaryButton(label: 'Decline', onPressed: () => _respond(false))),
          ]),
      ]),
    );
  }
}
