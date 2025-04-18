import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getUserId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  } catch (e) {
    print('Error getting userId: $e');
    return null;
  }
}
