import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'post_provider.dart';
import 'post_api_service.dart';

// --- COLOR PALETTE FROM HTML ---
const kColorPrimary = Color(0xFFB41B00);
const kColorPrimaryContainer = Color(0xFFFF775D);
const kColorBackground = Color(0xFFFFF4F3);
const kColorSurfaceLow = Color(0xFFFFEDEC);
const kColorSurfaceHighest = Color(0xFFFFD2D3);
const kColorOnSurface = Color(0xFF4D2124);
const kColorOnSurfaceVariant = Color(0xFF834C4F);
const kColorTertiary = Color(0xFFFFD709);

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
    _isFetchingMore = true;
    final provider = Provider.of<PostProvider>(context, listen: false);
    int skip = provider.posts.length;
    final newPosts = await PostApiService.getPosts(
      _limit.toString(),
      skip.toString(),
    );
    if (newPosts.isNotEmpty) provider.addPosts(newPosts);
    _isFetchingMore = false;
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
      backgroundColor: kColorBackground,
      body: RefreshIndicator(
        color: kColorPrimary,
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
                        child: CircularProgressIndicator(color: kColorPrimary),
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
              profilePictureUrl: postData['post']['owner']['profile_picture_url'].toString(),
              timeDifference: getTimeAgo(postData['post']['created_at']),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 16),
      decoration: BoxDecoration(color: kColorBackground.withOpacity(0.7)),
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
                    color: kColorPrimary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: kColorSurfaceHighest,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'RANKED',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: kColorPrimary,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
          const Icon(Icons.bolt, color: kColorPrimary, size: 28),
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
            color: kColorSurfaceHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: Icon(Icons.add, color: kColorPrimary)),
        ),
        const SizedBox(height: 8),
        Text(
          "Your Pulse",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: kColorOnSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class TextPost extends StatelessWidget {
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
    required this.timeDifference
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

  // Der Controller muss hier bleiben, damit deine Logik funktioniert
  final commentController = TextEditingController();

  Future<void> _fetchData(BuildContext context) async {
    final provider = Provider.of<PostProvider>(context, listen: false);
    provider.setLoadingComments(true);
    final comments = await PostApiService.getComments(post_id);
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
            color: kColorBackground, // Nutzt die neue Background-Farbe
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
                  color: kColorPrimary.withOpacity(0.1),
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
                    color: kColorOnSurface,
                  ),
                ),
              ),

              // Kommentar-Liste
              Expanded(
                child: Consumer<PostProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingComments) {
                      return const Center(
                        child: CircularProgressIndicator(color: kColorPrimary),
                      );
                    }
                    if (provider.comments.isEmpty) {
                      return Center(
                        child: Text(
                          "Be the first to pulse!",
                          style: TextStyle(color: kColorOnSurfaceVariant),
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
                            color: kColorOnSurfaceVariant.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: kColorSurfaceHighest.withOpacity(0.3),
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
                          colors: [kColorPrimary, kColorPrimaryContainer],
                        ),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) return;
                          final success = await PostApiService.postComment(
                            post_id,
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
        color: kColorSurfaceLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withOpacity(0.02),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), _buildBody(), _buildFooter(context)],
      ),
    );
  }

  Widget _buildHeader() {
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
              color: kColorSurfaceHighest,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: profilePictureUrl != null
                  ? Image.network(
                profilePictureUrl.toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _avatarFallback(owner_username),
              )
                  : _avatarFallback(owner_username),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kColorTertiary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kColorSurfaceLow, width: 2),
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
        owner_username,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "$timeDifference • LIFESTYLE",
        style: TextStyle(fontSize: 10),
      ),
      trailing: const Icon(Icons.more_horiz),
    );
  }

  Widget _avatarFallback(String name) => Container(
    color: kColorSurfaceHighest,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: Color(0xFFB41B00),
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
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (imageUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            content,
            style: const TextStyle(color: kColorOnSurfaceVariant),
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
              color: kColorOnSurfaceVariant,
            ),
          ),
          const Spacer(),
          const Icon(Icons.share_outlined, color: kColorOnSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildHypeButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final success = await PostApiService.createVote(post_id, 1);
        if (success)
          Provider.of<PostProvider>(
            context,
            listen: false,
          ).addLikeLocally(post_id);
      },
      onDoubleTap: () async {
        final success = await PostApiService.createVote(post_id, 0);

        if (success) {
          Provider.of<PostProvider>(
            context,

            listen: false,
          ).removeLikeLocally(post_id);
        } else {

        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kColorPrimary, kColorPrimaryContainer],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: kColorPrimary.withOpacity(0.2),
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
              likes.toString(),
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
                colors: [kColorPrimary, kColorPrimaryContainer],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: kColorBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kColorBackground, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(color: kColorSurfaceHighest),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: kColorOnSurface,
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
            backgroundColor: const Color(0xFFFFD2D3),
            radius: 18,
            child: Text(
              username[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFB41B00),
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
                color: const Color(0xFFFBB4B6).withOpacity(0.2),
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
                      color: Color(0xFF4D2124),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment,
                    style: const TextStyle(
                      color: Color(0xFF4D2124),
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
