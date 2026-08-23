import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A lightweight stand-in for real user accounts: each install generates
/// and persists its own random ID, which is what gets shared (via the
/// invite link on the Co-Keeper Invite screen) to pair two devices without
/// needing a full sign-up/login system. Good enough for "my one trusted
/// person holds my key" -- not meant to survive a reinstall or support
/// multiple devices per person, which real accounts (Firebase Auth) would
/// be needed for later.
class OneirIdentity {
  OneirIdentity._();

  static const _idKey = 'oneir_device_id';
  static const _pairedCoKeeperIdKey = 'paired_co_keeper_id';

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_idKey);
    if (existing != null) return existing;
    final newId = const Uuid().v4();
    await prefs.setString(_idKey, newId);
    return newId;
  }

  /// Set once this device's Co-Keeper invite has been accepted -- the ID of
  /// the device that's now holding this user's key.
  static Future<void> savePairedCoKeeperId(String coKeeperId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pairedCoKeeperIdKey, coKeeperId);
  }

  static Future<String?> getPairedCoKeeperId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pairedCoKeeperIdKey);
  }

  static Future<void> clearPairedCoKeeperId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pairedCoKeeperIdKey);
  }
}
