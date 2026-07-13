import 'package:flutter/material.dart';

// Kommentare haben ihren eigenen Provider (statt im PostProvider mitzuwohnen):
// notifyListeners() weckt immer ALLE Zuhoerer eines Providers — solange die
// Kommentare im PostProvider lagen, hat jedes Kommentar-Event (Sheet oeffnen,
// Kommentare laden) den kompletten Feed dahinter mit-rebuildet.
class CommentProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get comments => _comments;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setComments(List<Map<String, dynamic>> fetchComments) {
    _comments = fetchComments;
    _isLoading = false;
    notifyListeners();
  }
}