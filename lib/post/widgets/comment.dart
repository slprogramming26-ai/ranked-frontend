import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';
import '../../user_api_service.dart';

class Comment extends StatelessWidget {
  const Comment({
    super.key,
    required this.comment,
    this.commentId,
    this.username = "User", // Default Value für später
  });

  final int? commentId;
  final String comment;
  final String username;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Lange drücken -> Kommentar melden.
      onLongPress: commentId == null ? null : () => _showReportSheet(context),
      child: Padding(
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
              style: TextStyle(
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment,
                    style: TextStyle(
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
      ),
    );
  }

  // Grund-Sheet: zeigt die festen Melde-Gründe. Tap auf einen Grund
  // schließt das Sheet und schickt den Report ab.
  void _showReportSheet(BuildContext context) {
    const reasons = [
      'Spam',
      'Belästigung oder Mobbing',
      'Unangemessener Inhalt',
      'Falschinformation',
      'Sonstiges',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle-Bar
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
                  "Kommentar melden",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              ...reasons.map(
                (reason) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(sheetContext); // Sheet zu
                      _sendReport(context, reason);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  // Schickt den Report ans Backend und gibt Feedback per Snackbar.
  Future<void> _sendReport(BuildContext context, String reason) async {
    final messenger = ScaffoldMessenger.of(context);
    final status = await UserApiService.report(commentId!, "comment", reason);

    final String message;
    if (status == 201) {
      message = "Danke! Wir schauen uns das an.";
    } else if (status == 409) {
      message = "Du hast diesen Kommentar bereits gemeldet.";
    } else {
      message = "Melden fehlgeschlagen. Versuch es später erneut.";
    }

    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}