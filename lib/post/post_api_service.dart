import 'dart:convert';
import 'dart:io';
import '../api_client.dart';

/// Wird von [PostApiService.getPosts] geworfen, wenn der lokale Feed
/// angefragt wird, der User aber keinen Ort gesetzt hat (Backend: 400).
/// So kann der Feed "kein Ort" von "Ort hat einfach keine Posts" (leere
/// Liste) unterscheiden und den Location-Picker anbieten.
class NoLocationException implements Exception {}

class PostApiService {
  // Für Android Emulator: 10.0.2.2, für echtes Gerät: deine lokale IP
  static const String baseUrl = 'https://web-production-1bb6f.up.railway.app';

  static Future<List<Map<String, dynamic>>> getPosts(
      String limit, String skip,
      {bool local = false}) async {
    final localParam = local ? '&local=true' : '';
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/posts/?limit=$limit&skip=$skip$localParam'),
    );
    if (response.statusCode == 200) {
      // bodyBytes + utf8.decode: ohne charset im Content-Type raet http
      // Latin-1 — Umlaute in Ortsnamen/Texten wuerden sonst garbeln.
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.cast<Map<String, dynamic>>();
    }
    if (local && response.statusCode == 400) {
      throw NoLocationException();
    }
    return [];
  }

  /// Holt einen einzelnen Post per ID (z. B. wenn im Chat ein geteilter
  /// Post-Link getippt wird). Liefert dieselbe Struktur wie ein Eintrag aus
  /// [getPosts] – also `{post, votes, is_mine, is_liked}` – oder `null`, wenn
  /// der Post nicht existiert (404) bzw. ein Fehler auftritt.
  static Future<Map<String, dynamic>?> getPostById(int id) async {
    final response = await ApiClient.get(
      Uri.parse('$baseUrl/posts/$id'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> createPost(String title, String content, bool published,
      String? imageUrl, String? flag,
      {int? locationId}) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/posts/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'content': content,
        'published': published,
        'image_url': imageUrl,
        'flag': flag,
        // null = Post erbt den Heimatort des Users (macht das Backend);
        // eine explizite id ueberschreibt ihn nur fuer diesen Post.
        'location_id': locationId,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<bool> createVote(int post_id, int dir) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/vote/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"post_id": post_id, "dir": dir}),
    );
    return response.statusCode == 201;
  }

  static Future<String?> uploadPostImage(File imageFile) async {
    final response = await ApiClient.uploadFile(
      Uri.parse('$baseUrl/posts/upload'),
      imageFile,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['image_url'] as String;
    }
    print('Upload fehlgeschlagen: ${response.statusCode} – ${response.body}'); // <-- zeigt detail
    return null;
  }

  static Future<List<Map<String, dynamic>>> getComments(int post_id) async {
    final response =
        await ApiClient.get(Uri.parse('$baseUrl/comment/$post_id'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print('COMMENTS RAW: $data');
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<bool> postComment(int post_id, String comment) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/comment/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'post_id': post_id,
        'comment': comment,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<bool> deletePost(int id) async {
    final response = await ApiClient.delete(Uri.parse('$baseUrl/posts/$id'));
    return response.statusCode == 204;
  }



}