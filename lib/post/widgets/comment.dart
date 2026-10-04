import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../moderation/report_sheet.dart';
import '../../moderation/report_target.dart';
import 'collapse_out.dart';

// Stateful, weil der Kommentar nach dem Melden erst wegklappt (_hiding) und
// erst danach per [onHidden] wirklich aus der Liste fliegt.
class Comment extends StatefulWidget {
  const Comment({
    super.key,
    required this.comment,
    this.commentId,
    this.username = "User", // Default Value für später
    this.onHidden,
  });

  final int? commentId;
  final String comment;
  final String username;

  // Wird am Ende der Wegklapp-Animation aufgerufen. Der Aufrufer entfernt
  // den Kommentar dann aus seiner Liste (CommentsNotifier.hide).
  final VoidCallback? onHidden;

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  bool _hiding = false;

  // Lange drücken -> Kommentar melden. Das Sheet kommt aus lib/moderation,
  // true heisst "Senden getippt" (gesendet wird im Hintergrund).
  Future<void> _report() async {
    final onHidden = widget.onHidden;
    final reported = await showReportSheet(
      context,
      target: ReportTarget.comment,
      id: widget.commentId!,
    );
    if (!reported) return;
    // Sheet zu, waehrend das Melde-Sheet offen war: ohne Animation entfernen.
    if (!mounted) return onHidden?.call();
    setState(() => _hiding = true);
  }

  @override
  Widget build(BuildContext context) {
    return CollapseOut(
      collapsed: _hiding,
      onCollapsed: () => widget.onHidden?.call(),
      child: GestureDetector(
        onLongPress: widget.commentId == null ? null : _report,
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
                  widget.username[0].toUpperCase(),
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
                        widget.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.comment,
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
      ),
    );
  }
}
