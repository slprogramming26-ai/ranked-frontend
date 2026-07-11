import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ranked/search.dart';
import 'post_provider.dart';
import 'post_api_service.dart';
import 'widgets/comment.dart';
import 'widgets/story_avatar.dart';
import 'widgets/share_sheet.dart';
import 'widgets/text_post.dart';
import '../user_api_service.dart';
import 'dart:ui';
import '../app_colors.dart';
import 'package:ranked/story/story_create_screen.dart';
import 'package:ranked/story/story_viewer.dart';
import 'package:ranked/story/story.dart';
import 'package:ranked/local_data/database.dart';
import 'package:ranked/messenger/messenger_controller.dart';
// Noetig fuer die Extension-Methoden auf dem Service (sendDirectMessage,
// sendGroupMessage, isConnected, reconnect) — die leben in Part-Dateien
// dieser Library und sind sonst nicht im Scope.
import 'package:ranked/messenger/messenger_api_service.dart';

class PostsFeed extends StatefulWidget {
  const PostsFeed({super.key});

  @override
  State<PostsFeed> createState() => _PostsFeedState();
}

class _PostsFeedState extends State<PostsFeed> {
  final ScrollController _scrollController = ScrollController();
  final int _limit = 10;
  bool _isFetchingMore = false;
  // false sobald der Server einmal weniger als eine volle Seite geliefert hat
  // -> Feed ist zu Ende, kein weiteres Nachladen mehr.
  bool _hasMore = true;

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
    if (_isFetchingMore || !_hasMore) return;
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
      // Weniger als eine volle Seite = der Server hat nicht mehr.
      _hasMore = newPosts.length == _limit;
      _isFetchingMore = false;
    });
  }

  Future<void> _fetchData() async {
    final provider = Provider.of<PostProvider>(context, listen: false);
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    if (provider.posts.isEmpty) provider.setLoading(true);

    // Posts und Stories parallel laden (spart eine Round-Trip-Zeit).
    final results = await Future.wait([
      PostApiService.getPosts(_limit.toString(), "0"),
      StoryApiService.getStories(),
    ]);
    final posts = results[0];
    final stories = results[1];

    // Frischer Load: Nachladen wieder erlauben (wichtig nach Pull-to-Refresh,
    // wenn der Feed vorher schon ausgeschoepft war).
    _hasMore = posts.length == _limit;

    provider.setPosts(posts);
    storyProvider.setStories(stories);
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
                  Align(
                    alignment: Alignment.centerLeft,
                      child: _buildStoryRow(context)),
                ],
              );
            }

            if (index == postProvider.posts.length) {
              return _isFetchingMore
                  ? Padding(
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
              flag: postData['post']['flag'],
              isMine: postData['is_mine'] ?? false,
              isLiked: postData['is_liked'] ?? false,
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
          IconButton(icon: Icon(Icons.search, color: AppColors.primary, size: 28), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildStoryRow(BuildContext context) {
    return Consumer<StoryProvider>(
      builder: (context, storyProvider, _) {
        // Stories nach Owner gruppieren (eine Ring pro User, Instagram-Style).
        // Reihenfolge des Backends (neueste zuerst) bleibt erhalten.
        final grouped = <int, List<Map<String, dynamic>>>{};
        for (final story in storyProvider.stories) {
          final ownerId = story['owner_id'] as int;
          grouped.putIfAbsent(ownerId, () => []).add(story);
        }
        final owners = grouped.values.toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              _buildAddPulse(),
              if (storyProvider.isLoading && owners.isEmpty)
                // Platzhalter-Ringe während des ersten Ladens.
                ...List.generate(4, (_) => const StoryAvatarSkeleton())
              else
                ...List.generate(owners.length, (i) {
                  final stories = owners[i];
                  return ShowStoryAvatar(
                    stories: stories,
                    onTap: () => _openStoryViewer(owners, i),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _openStoryViewer(List<List<Map<String, dynamic>>> owners, int startIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => StoryViewer(owners: owners, initialOwner: startIndex),
      ),
    );
  }

  Widget _buildAddPulse() {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StoryCreateScreen()),
            );
          },
          child: Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ),
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
