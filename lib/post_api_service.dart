import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_storage.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class PostApiService {
  // Für Android Emulator: 10.0.2.2, für echtes Gerät: deine lokale IP
  static const String baseUrl = 'https://web-production-1bb6f.up.railway.app';

  static Future<List<Map<String, dynamic>>> getPosts(String limit,
      String skip) async {
    final token = await TokenStorage.getToken();
    print("Token: $token"); // NEU
    final response = await http.get(
      Uri.parse('$baseUrl/posts/?limit=$limit&skip=$skip'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print("Status: ${response.statusCode}"); // NEU
    print("Body: ${response.body}"); // NEU

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<bool> createPost(String title,
      String content,
      bool published,
      String? imageUrl,) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/posts/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'published': published,
        'image_url': imageUrl,
      }),
    );

    // NEU - zeigt uns was der Server genau zurückgibt

    return response.statusCode == 201;
  }

  static Future<bool> createVote(int post_id, int dir) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/vote/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"post_id": post_id, "dir": dir}),
    );
    print("Sende Vote an: $baseUrl/votes mit ID: $post_id");
    return response.statusCode == 201;
  }

  static Future<String?> uploadPostImage(File imageFile) async {
    final token = await TokenStorage.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath(
      'file', imageFile.path, contentType: MediaType('image', 'jpeg'),));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      return data['image_url'] as String;
    }

    // Ersetze die print Zeile mit:
    final error = jsonDecode(body);
    print('Upload fehlgeschlagen: ${response.statusCode} - ${error['detail']}');
    return null;

  }

  static Future<List<Map<String, dynamic>>> getComments(int post_id) async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
        Uri.parse('$baseUrl/comment/$post_id'),
        headers: {
          'Authorization': 'Bearer $token',
        }
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future <bool> postComment(int post_id, String comment) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/comment/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'post_id': post_id,
        'comment': comment,
      }),
    );

    return response.statusCode == 201;
  }
}