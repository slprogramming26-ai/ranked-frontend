import 'package:flutter/material.dart';

class PostProvider extends ChangeNotifier {

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _comments = [];

  bool _isLoading = false;
  bool _isLoadingComments = false;


  List<Map<String, dynamic>> get posts => _posts;
  List<Map<String, dynamic>> get comments => _comments;
  bool get isLoading => _isLoading;
  bool get isLoadingComments => _isLoadingComments;


  void setPosts(List<Map<String, dynamic>> fetchPosts) {
    _posts = fetchPosts;
    _isLoading = false;
    notifyListeners();
  }

  void addPosts(List<Map<String, dynamic>> newPosts) {
    _posts.addAll(newPosts); // Hängt die neuen Posts an die Liste an
    _isLoading = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setLoadingComments(bool loading) {
    _isLoadingComments = loading;
    notifyListeners();
  }

  void setComment(List<Map<String, dynamic>> fetchComments) {
    _comments = fetchComments;
    _isLoadingComments = false;
    notifyListeners();
  }


  // Setzt den Like-Status eines Posts und passt den Vote-Counter passend an.
  // Wird sowohl für optimistische Updates als auch für Rollbacks benutzt.
  void setLike(int postId, bool liked) {
    int index = _posts.indexWhere((element) => element['post']['id'] == postId);
    if (index == -1) return;

    final bool currentlyLiked = _posts[index]['is_liked'] == true;
    // Schon im gewünschten Zustand? Dann nichts tun (verhindert doppeltes Zählen).
    if (currentlyLiked == liked) return;

    _posts[index]['is_liked'] = liked;
    _posts[index]['votes'] = (_posts[index]['votes'] as int) + (liked ? 1 : -1);

    // WICHTIG: Sag den Widgets, dass sich etwas geändert hat!
    notifyListeners();
  }

}