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
        title: Text('Co-Keeper requests', style: TextStyle(fontFamily: 'PlusJakartaSans', color: OneirColors.text, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: CoKeeperBackend.watchPendingRequestsForMe(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return Center(
              child: Text('No pending requests', style: TextStyle(fontFamily: 'PlusJakartaSans', color: OneirColors.textFaint)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: OneirColors.cardNeutral, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$name wants to unlock $appPackage',
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 15, color: OneirColors.text)),
        if (reason.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Reason: $reason', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textMuted)),
        ],
        const SizedBox(height: 6),
        Text('Requesting $duration minutes', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: OneirColors.textFaint)),
        const SizedBox(height: 14),
        if (_responding)
          const Center(child: CircularProgressIndicator())
        else
          Row(children: [
            Expanded(child: OneirPrimaryButton(label: 'Approve', onPressed: () => _respond(true))),
            const SizedBox(width: 10),
            Expanded(child: OneirSecondaryButton(label: 'Decline', onPressed: () => _respond(false))),
          ]),
      ]),
    );
  }
}
