import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_stats_service.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = UserStatsService.instance;

    return AnimatedBuilder(
      animation: stats,
      builder: (context, _) {
        final displayName = stats.displayName.isNotEmpty ? stats.displayName : 'Mohammed Maaz';
        final email = stats.email.isNotEmpty ? stats.email : 'allanmaazimdad@gmail.com';
        final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';

        return Scaffold(
          backgroundColor: SaynColors.paperBg,
          appBar: AppBar(
            backgroundColor: SaynColors.paperBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: SaynColors.wineMaroon, size: 26),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Account',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: SaynColors.wineMaroon,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              children: [
                // ─── 1. MAIN PROFILE CARD WITH STATS & PLAN (Matching Screenshot 1) ───
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: SaynColors.paperCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: SaynColors.wineMaroon,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: SaynColors.wineMaroon,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: SaynColors.wineMaroon,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: SaynColors.paperBorder, height: 1),
                      const SizedBox(height: 16),

                      // Real-time Productivity Metrics (11 weeks, 22.3k words, 122 WPM)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            icon: Icons.local_fire_department_outlined,
                            value: stats.streakFormatted,
                          ),
                          Container(width: 1, height: 34, color: SaynColors.paperBorder),
                          _buildStatColumn(
                            icon: Icons.trending_up_rounded,
                            value: stats.totalWordsFormatted,
                          ),
                          Container(width: 1, height: 34, color: SaynColors.paperBorder),
                          _buildStatColumn(
                            icon: Icons.emoji_events_outlined,
                            value: stats.wpmFormatted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Manage Plan Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => _showPlanModal(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SaynColors.wineMaroon,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Manage plan',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── 2. LEGAL & DOCUMENTATION CARD ───
                Container(
                  decoration: BoxDecoration(
                    color: SaynColors.paperCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                  ),
                  child: Column(
                    children: [
                      _buildActionRow(
                        icon: Icons.description_outlined,
                        title: 'View privacy policy',
                        trailing: Icons.open_in_new_rounded,
                        onTap: () => _showPrivacyPolicy(context),
                      ),
                      const Divider(color: SaynColors.paperBorder, height: 1),
                      _buildActionRow(
                        icon: Icons.menu_book_outlined,
                        title: 'How to use SAYN on Android',
                        trailing: Icons.open_in_new_rounded,
                        onTap: () => _showUsageGuide(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── 3. RESET STATS / HISTORY CARD ───
                Container(
                  decoration: BoxDecoration(
                    color: SaynColors.paperCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                  ),
                  child: _buildActionRow(
                    icon: Icons.restart_alt_rounded,
                    title: 'Clear history & reset stats',
                    trailing: Icons.chevron_right_rounded,
                    onTap: () => _confirmReset(context),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: SaynColors.wineMaroon, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: SaynColors.wineMaroon,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required IconData trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: SaynColors.wineMaroon, size: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: SaynColors.wineMaroon,
                ),
              ),
            ),
            Icon(trailing, color: SaynColors.wineMaroon, size: 19),
          ],
        ),
      ),
    );
  }

  void _showPlanModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SaynColors.paperCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(Icons.verified_rounded, color: SaynColors.wineMaroon, size: 26),
                SizedBox(width: 10),
                Text(
                  'SAYN Studio Plan',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: SaynColors.wineMaroon,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Your account has full unlimited access to all AI grammar models, voice-to-text dictation, and real-time cloud synchronization.',
              style: TextStyle(fontSize: 13.5, color: SaynColors.paperText, height: 1.45),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SaynColors.paperSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(Icons.all_inclusive_rounded, color: SaynColors.wineMaroon, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Unlimited Cloud Sync & Custom Prompts Active',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: SaynColors.wineMaroon,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: SaynColors.wineMaroon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaynColors.paperCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'SAYN values your privacy. Audio recordings are processed in real-time and never permanently stored on servers. Only text snippets you explicitly refine are synchronized to your account database.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: SaynColors.wineMaroon, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showUsageGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaynColors.paperCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'How to use SAYN',
          style: TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('1. Smart Keyboard (IME):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SaynColors.wineMaroon)),
            Text('Slide the spacebar left or right to move the cursor character-by-character.', style: TextStyle(fontSize: 12.5)),
            SizedBox(height: 10),
            Text('2. Floating Mic Overlay:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SaynColors.wineMaroon)),
            Text('Tap the floating bubble anywhere on your phone to dictate into WhatsApp, Gmail, or Notes.', style: TextStyle(fontSize: 12.5)),
            SizedBox(height: 10),
            Text('3. Writing Studio:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SaynColors.wineMaroon)),
            Text('Paste any text to polish grammar or switch between Natural, Fluent, and Professional tones.', style: TextStyle(fontSize: 12.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: SaynColors.wineMaroon, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaynColors.paperCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset History & Stats',
          style: TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to clear your local writing history and reset your statistics to start fresh?',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: SaynColors.paperTextMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await UserStatsService.instance.clearHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Writing history and statistics reset.'),
                    backgroundColor: SaynColors.wineMaroon,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SaynColors.wineMaroon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
