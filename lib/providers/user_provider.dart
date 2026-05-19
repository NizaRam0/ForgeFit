import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _user;
  bool _isLoading = true;
  bool _localSetupDone = false;

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;

  // True if onboarding was completed locally OR the server profile has both
  // goal and equipment set. The local flag ensures we don't re-show onboarding
  // if the server returns incomplete data after the first successful setup.
  bool get isSetup =>
      _localSetupDone ||
      (_user != null &&
        (_user!.profileComplete ||
          _user!.goal.isNotEmpty &&
        _user!.availableEquipment.isNotEmpty));

    bool get profileComplete => isSetup;

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _localSetupDone = prefs.getBool('profile_complete') ??
          prefs.getBool('setup_complete') ??
          false;

      final profile = await AuthService.instance.getProfile();
      _user = profile != null
          ? UserProfile.fromJson(Map<String, dynamic>.from(profile))
          : null;

      if (_user != null &&
          (_user!.profileComplete ||
              (_user!.goal.isNotEmpty && _user!.availableEquipment.isNotEmpty))) {
        _localSetupDone = true;
        await prefs.setBool('profile_complete', true);
        await prefs.setBool('setup_complete', true);
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveUser(UserProfile profile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated =
          await AuthService.instance.updateProfile(profile.toApiJson());
      if (updated != null) {
        _user = UserProfile.fromJson(Map<String, dynamic>.from(updated))
            .copyWith(profileComplete: true);
        // Persist setup-complete flag so the app doesn't loop back to onboarding
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('profile_complete', true);
        await prefs.setBool('setup_complete', true);
        _localSetupDone = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving user: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(UserProfile profile) => saveUser(profile);

  Future<void> clearUser() async {
    _user = null;
    _localSetupDone = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_complete');
    await prefs.remove('setup_complete');
    notifyListeners();
  }
}
