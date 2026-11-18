import 'package:flutter/material.dart';
import '../profile/profile.dart';
import 'package:provider/provider.dart';
import '../ui/app_colors.dart';
import 'ranking_leaderboard.dart';
import 'ranking_optin.dart';

// ─── RankingHome ─────────────────────────────────────────────────────────────
class RankingHome extends StatefulWidget {
  const RankingHome({super.key});

  @override
  State<RankingHome> createState() => _RankingHomeState();
}

class _RankingHomeState extends State<RankingHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context);

    if (profile.isLoading || profile.userdata.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (profile.userdata["ranking_enabled"] == true) {
      return const RankingEnabledView();
    }
    return const RankingOptinView();
  }
}
