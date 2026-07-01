import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';

import '../api_client.dart';

class StoryApiService {

  static const String baseUrl = 'https://web-production-1bb6f.up.railway.app';

  static Future<List<Map<String, dynamic>>> getStories() async {
    final response = await ApiClient.get(Uri.parse("$baseUrl/stories/"));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }


  static Future<Map<String, dynamic>?> uploadStory(File imageFile) async {
    final response = await ApiClient.uploadFile(
      Uri.parse('$baseUrl/stories/upload'),
      imageFile,
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    print('Upload fehlgeschlagen: ${response.statusCode} – ${response.body}');
    return null;
  }

  static Future<bool> deleteStory(int storyId) async {
    final response = await ApiClient.delete(Uri.parse("$baseUrl/stories/$storyId"));
    return response.statusCode == 204;
  }
}


class StoryProvider extends ChangeNotifier {

  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get stories => _stories;
  bool get isLoading => _isLoading;

  // Ersetzt die ganze Liste (nach dem Fetch). notifyListeners() ist Pflicht,
  // sonst rebuildet die Story-Row nicht.
  void setStories(List<Map<String, dynamic>> loadedStories) {
    _stories = loadedStories;
    _isLoading = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Nach erfolgreichem Upload: neue Story vorne einfügen (Backend sortiert desc,
  // also Neuste zuerst), damit sie sofort in der Row auftaucht.
  void addStory(Map<String, dynamic> story) {
    _stories.insert(0, story);
    notifyListeners();
  }

  // Nach erfolgreichem Löschen: Story per id aus der Liste werfen.
  void removeStory(int storyId) {
    _stories.removeWhere((s) => s['id'] == storyId);
    notifyListeners();
  }

}