import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ranked/search.dart';
import 'post_provider.dart';
import 'post_api_service.dart';
import 'widgets/story_avatar.dart';
import 'widgets/text_post.dart';
import 'widgets/feed_skeleton.dart';
import 'widgets/feed_entrance.dart';
import '../app_colors.dart';
import '../location_picker.dart';
import '../user_api_service.dart';
import 'package:ranked/story/story_create_screen.dart';
import 'package:ranked/story/story_viewer.dart';
import 'package:ranked/story/story.dart';

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

  // Choreografie: Posts/Stories animieren nur bei ihrem ERSTEN Erscheinen.
  // Ohne dieses Gedaechtnis wuerde Hochscrollen (ListView baut Items neu)
  // dieselben Posts immer wieder einfliegen lassen.
  final Set<int> _seenPostIds = {};
  bool _storiesShown = false;

  // true, wenn der Lokal-Feed 400 geliefert hat ("user has no location set")
  // -> Empty-State mit "Ort waehlen"-Button statt leerem Feed.
  bool _noLocation = false;

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

  // Umschalten "Fuer dich" <-> "Lokal": Provider tauscht Liste+Modus atomar,
  // hier wird nur der Paging-/Animations-State des Widgets zurueckgesetzt.
  void _switchFeed(bool local) {
    final provider = Provider.of<PostProvider>(context, listen: false);
    if (provider.isLocalFeed == local) return;
    provider.switchFeed(local);
    setState(() {
      _hasMore = true;
      _isFetchingMore = false;
      _noLocation = false;
      _seenPostIds.clear();
    });
    _fetchData();
  }

  Future<void> _fetchMoreData() async {
    if (_isFetchingMore || !_hasMore) return;
    final provider = Provider.of<PostProvider>(context, listen: false);
    // Nachladen braucht eine erste Seite — die ist der Job von _fetchData.
    // Bei leerer Liste (Feed-Umschalten, Initial-Load, Empty-State) ist
    // maxScrollExtent ~0, die Scroll-Bedingung damit IMMER wahr, und ohne
    // diesen Guard wuerde parallel zu _fetchData dieselbe Seite 0 geladen
    // (doppelte Posts -> doppelte ValueKeys -> Exception).
    if (provider.posts.isEmpty) return;
    setState(() {
      _isFetchingMore = true;
    });
    int skip = provider.posts.length;
    // Merken, fuer welchen Feed diese Anfrage laeuft — schaltet der User
    // waehrend des await um, gehoert die Antwort zum falschen Feed.
    final bool wantLocal = provider.isLocalFeed;
    try {
      final newPosts = await PostApiService.getPosts(
        _limit.toString(),
        skip.toString(),
        local: wantLocal,
      );
      // Veraltete Antwort verwerfen; _isFetchingMore hat _switchFeed schon
      // zurueckgesetzt.
      if (provider.isLocalFeed != wantLocal) return;
      if (newPosts.isNotEmpty) provider.addPosts(newPosts);
      // Waehrend des await kann der Screen weggeraeumt worden sein (z.B.
      // Logout) — setState auf einem toten State wirft sonst eine Exception.
      if (!mounted) return;
      setState(() {
        // Weniger als eine volle Seite = der Server hat nicht mehr.
        _hasMore = newPosts.length == _limit;
        _isFetchingMore = false;
      });
    } catch (_) {
      // Netzfehler: Flag zuruecksetzen, sonst blockiert _isFetchingMore jedes
      // weitere Nachladen fuer immer. Naechster Scroll versucht es erneut.
      if (!mounted) return;
      setState(() => _isFetchingMore = false);
    }
  }

  Future<void> _fetchData() async {
    final provider = Provider.of<PostProvider>(context, listen: false);
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    final bool wantLocal = provider.isLocalFeed;
    if (provider.posts.isEmpty) provider.setLoading(true);
    // Ohne das hier blieb isLoading beim StoryProvider fuer immer false ->
    // die Skeleton-Ringe in _buildStoryRow wurden nie angezeigt.
    if (storyProvider.stories.isEmpty) storyProvider.setLoading(true);

    try {
      // Posts und Stories parallel laden (spart eine Round-Trip-Zeit).
      final results = await Future.wait([
        PostApiService.getPosts(_limit.toString(), "0", local: wantLocal),
        StoryApiService.getStories(),
      ]);
      // Hat der User waehrend des await umgeschaltet, gehoert diese Antwort
      // zum falschen Feed — verwerfen, der neue Fetch laeuft schon.
      if (provider.isLocalFeed != wantLocal) return;
      final posts = results[0];
      final stories = results[1];

      // Frischer Load: Nachladen wieder erlauben (wichtig nach Pull-to-Refresh,
      // wenn der Feed vorher schon ausgeschoepft war).
      _hasMore = posts.length == _limit;
      if (mounted && _noLocation) setState(() => _noLocation = false);

      provider.setPosts(posts);
      storyProvider.setStories(stories);
    } on NoLocationException {
      // 400 vom Lokal-Feed: User hat (noch) keinen Ort gesetzt. Statt Posts
      // zeigt der Feed den Empty-State mit "Ort waehlen"-Button. Die Stories
      // aus dem Future.wait gehen dabei verloren — verschmerzbar, die
      // Story-Row behaelt einfach ihren letzten Stand.
      if (provider.isLocalFeed != wantLocal) return;
      provider.setPosts([]); // beendet auch das isLoading der Skeletons
      storyProvider.setLoading(false);
      if (mounted) setState(() => _noLocation = true);
    } catch (_) {
      // Ohne Netz: Lade-Skeletons beenden statt ewig zu laden. Pull-to-Refresh
      // kann es jederzeit erneut versuchen.
      provider.setLoading(false);
      storyProvider.setLoading(false);
    }
  }

  // Wird vom Empty-State aufgerufen: Ort waehlen -> speichern -> Feed laden.
  Future<void> _pickLocationForFeed() async {
    final loc = await showLocationPicker(context);
    if (loc == null || !mounted) return;
    final ok = await UserApiService.setLocation(loc['id'] as int);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ort konnte nicht gespeichert werden')),
      );
      return;
    }
    setState(() => _noLocation = false);
    _fetchData();
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
    // Erstes Laden: noch keine Posts da und der Fetch laeuft -> Skeletons.
    final bool initialLoading =
        postProvider.isLoading && postProvider.posts.isEmpty;
    // Lokal-Feed ohne Inhalt (kein Ort gesetzt ODER Ort hat keine Posts):
    // statt des Lade-Spacers einen erklaerenden Empty-State zeigen.
    final bool showLocalEmptyState = !initialLoading &&
        postProvider.isLocalFeed &&
        postProvider.posts.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _fetchData(),
        child: ListView.builder(
          controller: _scrollController,
          // Waehrend des ersten Ladens: Header/Story-Row + ein Skeleton-Block.
          // Sonst: Header + alle Posts + 1 Loader/Spacer-Slot am Ende.
          itemCount: initialLoading || showLocalEmptyState
              ? 2
              : postProvider.posts.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  _buildStickyHeader(context),
                  _buildFeedToggle(postProvider.isLocalFeed),
                  Align(
                    alignment: Alignment.centerLeft,
                      child: _buildStoryRow(context)),
                ],
              );
            }

            if (initialLoading) {
              return const FeedSkeleton();
            }

            if (showLocalEmptyState) {
              return _buildLocalEmptyState();
            }

            if (index == postProvider.posts.length + 1) {
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
            final int postId = postData['post']['id'];
            // Nur beim ersten Erscheinen animieren; danach steht der Post
            // sofort da (z.B. beim Hochscrollen oder nach Pull-to-Refresh).
            final bool isNew = !_seenPostIds.contains(postId);
            if (isNew) _seenPostIds.add(postId);
            // Staffelung nur fuer die erste Seite (die erscheint als Block
            // nach dem Skeleton). Nachgeladene Posts mounten beim Scrollen
            // ohnehin einzeln -> sofort einblenden, ohne Wartezeit.
            final int delay = isNew && index <= _limit ? (index - 1) * 70 : 0;

            return FeedEntrance(
              key: ValueKey(postId),
              animate: isNew,
              delayMs: delay,
              child: TextPost(
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
                locationName: postData['post']['location']?['name'],
                isMine: postData['is_mine'] ?? false,
                isLiked: postData['is_liked'] ?? false,
              ),
            );
          },
        ),
      ),
    );
  }

  // Segmented-Pill "Fuer dich | Lokal" unter dem Header.
  Widget _buildFeedToggle(bool isLocal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            _toggleSegment('Für dich', !isLocal, () => _switchFeed(false)),
            _toggleSegment('Lokal', isLocal, () => _switchFeed(true)),
          ],
        ),
      ),
    );
  }

  Widget _toggleSegment(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  // Empty-State des Lokal-Feeds: entweder fehlt der Ort (mit Picker-Button)
  // oder der Ort hat schlicht noch keine Posts.
  Widget _buildLocalEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
      child: Column(
        children: [
          Icon(
            _noLocation
                ? Icons.location_off_rounded
                : Icons.location_on_outlined,
            size: 48,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _noLocation
                ? 'Kein Ort gesetzt'
                : 'Noch nichts los hier',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _noLocation
                ? 'Wähle deinen Ort, um Posts aus deiner Umgebung zu sehen.'
                : 'An deinem Ort wurde noch nichts gepostet — sei die/der Erste!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (_noLocation) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickLocationForFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.location_on_rounded, size: 18),
              label: Text(
                'Ort wählen',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 16),
      decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.7)),
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

        // Nur der allererste Auftritt der Ringe wird gestaffelt animiert.
        // Flag ohne setState setzen ist hier ok: es soll erst beim NAECHSTEN
        // Build false sein, dieser Build laeuft mit dem alten Wert weiter.
        final bool animateStories = !_storiesShown;
        if (owners.isNotEmpty) _storiesShown = true;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              _buildAddPulse(),
              if (storyProvider.isLoading && owners.isEmpty)
                // Platzhalter-Ringe während des ersten Ladens — EINE
                // Puls-Hülle um alle, damit sie synchron atmen.
                SkeletonPulse(
                  child: Row(
                    children:
                        List.generate(4, (_) => const StoryAvatarSkeleton()),
                  ),
                )
              else
                ...List.generate(owners.length, (i) {
                  final stories = owners[i];
                  return FeedEntrance(
                    animate: animateStories,
                    delayMs: i * 60,
                    child: ShowStoryAvatar(
                      stories: stories,
                      onTap: () => _openStoryViewer(owners, i),
                    ),
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
