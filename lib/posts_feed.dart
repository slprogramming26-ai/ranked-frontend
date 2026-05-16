import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'post_provider.dart';
import 'post_api_service.dart';
import 'dart:ui';
import 'app_colors.dart';

class PostsFeed extends StatefulWidget {
  const PostsFeed({super.key});

  @override
  State<PostsFeed> createState() => _PostsFeedState();
}

class _PostsFeedState extends State<PostsFeed> {
  final ScrollController _scrollController = ScrollController();
  final int _limit = 10;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        _fetchMoreData();
      }
    });
  }

  Future<void> _fetchMoreData() async {
    if (_isFetchingMore) return;
    setState(() {
      _isFetchingMore = true;
    });
    final provider = Provider.of<PostProvider>(context, listen: false);
    int skip = provider.posts.length;
    final newPosts = await PostApiService.getPosts(
      _limit.toString(),
      skip.toString(),
    );
    if (newPosts.isNotEmpty) provider.addPosts(newPosts);
    setState(() {
      _isFetchingMore = false;
    });
  }

  Future<void> _fetchData() async {
    final provider = Provider.of<PostProvider>(context, listen: false);
    if (provider.posts.isEmpty) provider.setLoading(true);
    final posts = await PostApiService.getPosts("10", "0");
    provider.setPosts(posts);
  }

  String getTimeAgo(String createdAt) {
    final dateTime = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Min.';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Std.';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays} Tagen';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'vor $weeks Wochen';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'vor $months Monaten';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'vor $years Jahren';
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _fetchData(),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: postProvider.posts.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  _buildStickyHeader(context),
                  _buildStoryRow(context),
                ],
              );
            }

            if (index == postProvider.posts.length) {
              return _isFetchingMore
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  : const SizedBox(height: 100);
            }

            final postData = postProvider.posts[index - 1];
            return TextPost(
              title: postData['post']['title'],
              content: postData['post']['content'],
              owner_username: postData['post']['owner']['username'].toString(),
              created_at: DateTime.parse(postData['post']['created_at']),
              likes: postData['votes'],
              post_id: postData['post']['id'],
              imageUrl: postData['post']['image_url'],
              profilePictureUrl:
                  postData['post']['owner']['profile_picture_url'].toString(),
              timeDifference: getTimeAgo(postData['post']['created_at']),
              category: postData['post']['category'],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 16),
      decoration: BoxDecoration(color: AppColors.surface.withOpacity(0.7)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: AppColors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'RANKED',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
          const Icon(Icons.bolt, color: AppColors.primary, size: 28),
        ],
      ),
    );
  }

  Widget _buildStoryRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          _buildAddPulse(),
          const ShowStoryAvatar(name: "Marcus"),
          const ShowStoryAvatar(name: "Elena"),
          const ShowStoryAvatar(name: "Sarah"),
          const ShowStoryAvatar(name: "David"),
        ],
      ),
    );
  }

  Widget _buildAddPulse() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: Icon(Icons.add, color: AppColors.primary)),
        ),
        const SizedBox(height: 8),
        Text(
          "Your Pulse",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class TextPost extends StatefulWidget {
  TextPost({
    super.key,
    required this.title,
    required this.content,
    required this.owner_username,
    required this.created_at,
    required this.likes,
    required this.post_id,
    this.imageUrl,
    this.profilePictureUrl,
    this.category,
    required this.timeDifference,
  });

  final String title;
  final String content;
  final String owner_username;
  final DateTime created_at;
  final int likes;
  final int post_id;
  final String? imageUrl;
  final String? profilePictureUrl;
  final String timeDifference;
  final String? category;

  @override
  State<TextPost> createState() => _TextPostState();
}

class _TextPostState extends State<TextPost> {
  // Der Controller muss hier bleiben, damit deine Logik funktioniert
  late TextEditingController commentController;

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
  }


  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }


  Future<void> _fetchData(BuildContext context) async {
    final provider = Provider.of<PostProvider>(context, listen: false);
    provider.setLoadingComments(true);
    final comments = await PostApiService.getComments(widget.post_id);
    provider.setComment(comments);
  }

  void showCommentSection(BuildContext context) async {
    _fetchData(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.surface, // Nutzt die neue Background-Farbe
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Comments",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),

              // Kommentar-Liste
              Expanded(
                child: Consumer<PostProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingComments) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }
                    if (provider.comments.isEmpty) {
                      return Center(
                        child: Text(
                          "Be the first to pulse!",
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 20),
                      children: provider.comments.map((commentData) {
                        return Comment(
                          comment: commentData['comment'],
                          username: commentData['username'] ?? "Anonymous",
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              // Eingabebereich
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Write a comment...",
                          hintStyle: TextStyle(
                            color: AppColors.onSurfaceVariant.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceContainerHighest.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryContainer],
                        ),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) return;
                          final success = await PostApiService.postComment(
                            widget.post_id,
                            commentController.text,
                          );
                          if (success) {
                            commentController.clear();
                            _fetchData(context);
                          }
                        },
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hier kommt das restliche UI aus meiner vorherigen Antwort rein (Container, Card, Hype Button etc.)
    // WICHTIG: Beim Kommentar-Button einfach showCommentSection(context) aufrufen!
    return _buildPostCard(context); // Wrapper für das Design von eben
  }

  // Das ist der visuelle Teil von eben, nur sauber verpackt:
  Widget _buildPostCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.02),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(context), _buildBody(), _buildFooter(context)],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: widget.profilePictureUrl != null
                  ? Image.network(
                      widget.profilePictureUrl.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _avatarFallback(widget.owner_username),
                    )
                  : _avatarFallback(widget.owner_username),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceContainerLow, width: 2),
              ),
              child: const Text(
                "#1",
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        widget.owner_username,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "${widget.timeDifference} • ${widget.category ?? ''}",
        style: TextStyle(fontSize: 10),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: () {
          showMiniMenu(context, widget.post_id.toString());
        },
      ),
    );
  }

  void showMiniMenu(BuildContext context, String post_id) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1), // Sanfterer Backdrop
      builder: (_) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0), // 2xl Style
            ),
            backgroundColor: Colors.white,
            elevation: 10,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: AppColors.primary.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Dialog passt sich dem Inhalt an
                children: [
                  _buildRankedButton(
                    icon: Icons.edit_outlined,
                    text: 'Edit Post',
                    color: AppColors.onSurface,
                    onTap: () {
                      // Deine Edit-Logik
                      Navigator.pop(context);
                    },
                  ),
                  _buildRankedButton(
                    icon: Icons.link_rounded,
                    text: 'Copy Link',
                    color: AppColors.onSurface,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(
                      color: AppColors.primary.withOpacity(0.1),
                      thickness: 1,
                    ),
                  ),
                  _buildRankedButton(
                    icon: Icons.delete_outline_rounded,
                    text: 'Delete Post',
                    color: AppColors.primary,
                    isBold: true,
                    onTap: () async {
                      print('Ausgelöst');
                      // final success = await PostApiService.deletePost(post_id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankedButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
    bool isBold = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: AppColors.surfaceContainerLow,
        splashColor: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              SizedBox(width: 14),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  fontFamily: 'Plus Jakarta Sans', // Falls im Projekt vorhanden
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) => Container(
    color: AppColors.surfaceContainerHighest,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    ),
  );

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            widget.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (widget.imageUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                widget.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            widget.content,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _buildHypeButton(context),
          const SizedBox(width: 15),
          IconButton(
            onPressed: () => showCommentSection(context),
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          const Icon(Icons.share_outlined, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildHypeButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final success = await PostApiService.createVote(widget.post_id, 1);
        if (success)
          Provider.of<PostProvider>(
            context,
            listen: false,
          ).addLikeLocally(widget.post_id);
      },
      onDoubleTap: () async {
        final success = await PostApiService.createVote(widget.post_id, 0);

        if (success) {
          Provider.of<PostProvider>(
            context,

            listen: false,
          ).removeLikeLocally(widget.post_id);
        } else {}
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryContainer],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              widget.likes.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShowStoryAvatar extends StatelessWidget {
  final String name;
  const ShowStoryAvatar({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(color: AppColors.surfaceContainerHighest),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  const Comment({
    super.key,
    required this.comment,
    this.username = "User", // Default Value für später
  });

  final String comment;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Kreis
          CircleAvatar(
            backgroundColor: AppColors.surfaceContainerHighest,
            radius: 18,
            child: Text(
              username[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Kommentar-Sprechblase
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
