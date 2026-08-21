import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'oneir_identity.dart';

/// Real-time Co-Keeper approve/decline over Firestore + push notifications,
/// replacing the earlier local-only stub. Data model:
///
///   users/{deviceId}                  -- { fcmToken }
///   pairings/{deviceId}               -- { coKeeperId, coKeeperName, status: pending|accepted }
///   requests/{requestId}              -- {
///                                          requesterId, requesterName,
///                                          coKeeperId, appPackage, reason,
///                                          status: pending|approved|declined,
///                                          createdAt, respondedAt,
///                                          durationMinutes
///                                        }
///
/// A Cloud Function (functions/index.js) listens for new `requests` docs and
/// sends the FCM push to the Co-Keeper's registered token -- that part runs
/// server-side and needs deploying separately (see SETUP.md).
class CoKeeperBackend {
  CoKeeperBackend._();

  static final _db = FirebaseFirestore.instance;

  /// Call once at app startup (after Firebase.initializeApp()) so this
  /// device can actually receive the push when someone requests a key from
  /// it, and so requesters can be notified when their request is answered.
  static Future<void> registerDeviceForPush() async {
    final deviceId = await OneirIdentity.getOrCreateDeviceId();
    await FirebaseMessaging.instance.requestPermission().timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw Exception('FCM permission request timed out (Firebase likely not configured)'),
        );
    final token = await FirebaseMessaging.instance.getToken().timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw Exception('FCM token fetch timed out (Firebase likely not configured)'),
        );
    if (token == null) return;
    await _db.collection('users').doc(deviceId).set({'fcmToken': token}, SetOptions(merge: true));

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _db.collection('users').doc(deviceId).set({'fcmToken': newToken}, SetOptions(merge: true));
    });
  }

  /// Creates the pairing record when a Co-Keeper invite is sent, so the
  /// person who opens the invite link can accept it and become linked.
  static Future<void> createPendingPairing({required String coKeeperName}) async {
    final deviceId = await OneirIdentity.getOrCreateDeviceId();
    await _db.collection('pairings').doc(deviceId).set({
      'coKeeperName': coKeeperName,
      'coKeeperId': null,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Called on the invitee's device when they open the invite link and tap
  /// Accept -- links the two devices together in both directions.
  static Future<void> acceptPairing(String requesterId) async {
    final myId = await OneirIdentity.getOrCreateDeviceId();
    await _db.collection('pairings').doc(requesterId).set({
      'coKeeperId': myId,
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await OneirIdentity.savePairedCoKeeperId(myId);
  }

  /// Sends a real request to the paired Co-Keeper. Returns the request ID
  /// so the caller can listen for the response.
  static Future<String> sendKeyRequest({
    required String appPackage,
    required String reason,
    required int durationMinutes,
  }) async {
    final deviceId = await OneirIdentity.getOrCreateDeviceId();
    final coKeeperId = await OneirIdentity.getPairedCoKeeperId();
    if (coKeeperId == null) {
      throw StateError('No paired Co-Keeper -- nothing to send the request to.');
    }
    final userName = await _requesterName(deviceId);

    final doc = await _db.collection('requests').add({
      'requesterId': deviceId,
      'requesterName': userName,
      'coKeeperId': coKeeperId,
      'appPackage': appPackage,
      'reason': reason,
      'durationMinutes': durationMinutes,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  static Future<String> _requesterName(String deviceId) async {
    final doc = await _db.collection('users').doc(deviceId).get();
    return (doc.data()?['name'] as String?) ?? 'Your friend';
  }

  /// Live status updates for a sent request -- 'pending', 'approved', or
  /// 'declined'. The interruption screen listens to this while showing
  /// "Waiting for approval...".
  static Stream<String> watchRequestStatus(String requestId) {
    return _db.collection('requests').doc(requestId).snapshots().map((doc) {
      return (doc.data()?['status'] as String?) ?? 'pending';
    });
  }

  /// For the Co-Keeper's own device: all pending requests waiting on them.
  static Stream<List<Map<String, dynamic>>> watchPendingRequestsForMe() async* {
    final myId = await OneirIdentity.getOrCreateDeviceId();
    yield* _db
        .collection('requests')
        .where('coKeeperId', isEqualTo: myId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Future<void> respondToRequest(String requestId, {required bool approved}) async {
    await _db.collection('requests').doc(requestId).update({
      'status': approved ? 'approved' : 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
}
