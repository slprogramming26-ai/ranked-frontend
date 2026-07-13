import 'package:flutter/material.dart';

// Verwaltet NUR die Feed-Posts (Kommentare leben im CommentProvider).
// Wichtig fuer die Performance: Der Feed abonniert diesen Provider im build —
// jede notifyListeners()-Glocke hier MUSS also feed-relevant sein.
class PostProvider extends ChangeNotifier {

  List<Map<String, dynamic>> _posts = [];

  bool _isLoading = false;

  // Welcher Feed liegt gerade in _posts? Flag und Liste gehoeren zusammen
  // und wechseln nur gemeinsam (switchFeed) — so koennen nie Posts des
  // einen Feeds unter dem Label des anderen stehen.
  bool _isLocalFeed = false;


  List<Map<String, dynamic>> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLocalFeed => _isLocalFeed;

  void switchFeed(bool local) {
    if (_isLocalFeed == local) return;
    _isLocalFeed = local;
    _posts = []; // alte Posts gehoeren zum anderen Feed
    _isLoading = true; // Feed zeigt sofort Skeletons statt alter Posts
    notifyListeners();
  }


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