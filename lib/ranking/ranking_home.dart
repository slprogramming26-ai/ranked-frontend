import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../user_api_service.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import 'ranking_provider.dart';
import 'ranking_widgets.dart';
import 'ranking_leaderboard.dart';

// ─── RankingHome ─────────────────────────────────────────────────────────────
class RankingHome extends StatefulWidget {
  const RankingHome({super.key});

  @override
  State<RankingHome> createState() => _RankingHomeState();
}

class _RankingHomeState extends State<RankingHome> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RankingProvider>(
        context,
        listen: false,
      ).fetchUserCredentials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RankingProvider>(context);

    if (provider.isLoadingHome || provider.userdata.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (provider.userdata["ranking_enabled"] == true) {
      return const RankingEnabledView();
    } else {
      // ── Opt-In Screen ──────────────────────────────────────────────────────
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tertiary.withOpacity(0.05),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    // Icon badge
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.leaderboard_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'JOIN THE\nRANKING',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aktiviere das Ranking und lass dich täglich von der Community bewerten — Productivity, Creativity & Engagement.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    // Activate Button
                    GradientButton(
                      label: 'AKTIVIEREN',
                      isLoading: _isLoading,
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        await UserApiService.setRankingEnabled(true);
                        await provider.fetchUserCredentials();
                        setState(() => _isLoading = false);
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
