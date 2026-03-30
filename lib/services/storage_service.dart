import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stamp.dart';

class StorageService {
  static const String _stampsKey = 'stamps_list';

  Future<List<Stamp>> loadStamps() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stampsJson = prefs.getString(_stampsKey);
    if (stampsJson == null) return [];

    try {
      final List<dynamic> decodedList = jsonDecode(stampsJson);
      return decodedList.map((s) => Stamp.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveStamp(Stamp stamp) async {
    final prefs = await SharedPreferences.getInstance();
    final stamps = await loadStamps();
    stamps.insert(0, stamp); // newest first
    final String updatedJson = jsonEncode(stamps.map((s) => s.toJson()).toList());
    await prefs.setString(_stampsKey, updatedJson);
  }

  Future<void> clearStamps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stampsKey);
  }
}
