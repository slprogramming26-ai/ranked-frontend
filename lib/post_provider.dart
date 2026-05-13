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


  void addLikeLocally(int postId) {
    // Wir suchen den Post in unserer Liste anhand der ID
    int index = _posts.indexWhere((element) => element['post']['id'] == postId);

    if (index != -1) {
      // Wir erhöhen die Zahl direkt im Speicher
      _posts[index]['votes'] = _posts[index]['votes'] + 1;

      // WICHTIG: Sag den Widgets, dass sich die Zahl geändert hat!
      notifyListeners();
    }
  }

  void removeLikeLocally(int postId) {
    int index = _posts.indexWhere((element) => element['post']['id'] == postId);

    if (index != -1) {

      _posts[index]['votes'] = _posts[index]['votes'] - 1;

      // WICHTIG: Sag den Widgets, dass sich die Zahl geändert hat!
      notifyListeners();
    }
  }

}