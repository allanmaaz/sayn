import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/user_stats_service.dart';
import '../account/account_screen.dart';
import '../settings/settings_screen.dart';

class SaynDrawer extends StatelessWidget {
  const SaynDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = UserStatsService.instance;

    return AnimatedBuilder(
      animation: stats,
      builder: (context, _) {
        final displayName = stats.displayName.isNotEmpty ? stats.displayName : 'Mohammed Maaz';
        final email = stats.email.isNotEmpty ? stats.email : 'allanmaazimdad@gmail.com';
        final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';

        return Drawer(
          backgroundColor: SaynColors.paperBg,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header with Logo & Brand Name (Matching Screenshot 4)
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: SaynColors.wineMaroon,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.graphic_eq_rounded,
                            color: SaynColors.warmCream,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'S A Y N',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          color: SaynColors.wineMaroon,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. User Profile Card
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AccountScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SaynColors.paperCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: SaynColors.wineMaroon,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: SaynColors.wineMaroon,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: SaynColors.wineMaroon,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: SaynColors.wineMaroon,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Weekly Word Usage Tracker (Real-Time Synced)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This week',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SaynColors.wineMaroon,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stats.weeklyUsageFormatted,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: SaynColors.wineMaroon,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stats.weeklyProgress > 0 ? stats.weeklyProgress : 0.04,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFEADECF),
                            valueColor: const AlwaysStoppedAnimation<Color>(SaynColors.wineMaroon),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: SaynColors.paperBorder, height: 1),
                  const SizedBox(height: 14),

                  // 4. Menu Actions
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Account',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AccountScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & feedback',
                    onTap: () {
                      Navigator.pop(context);
                      _showFeedbackDialog(context);
                    },
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: SaynColors.paperBorder, height: 1),
                  const SizedBox(height: 14),

                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About SAYN',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),

                  const Spacer(),

                  // Footer (Matching Screenshot 4: SAYN • v1.1.5)
                  const Center(
                    child: Text(
                      'SAYN  •  v1.1.5',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SaynColors.wineMaroon,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: SaynColors.wineMaroon, size: 22),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: SaynColors.wineMaroon,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaynColors.paperCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Help & Feedback',
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
            color: SaynColors.wineMaroon,
          ),
        ),
        content: const Text(
          'Have questions, feedback, or need assistance? Email our team directly at support@sayn.ai or allanmaazimdad@gmail.com.',
          style: TextStyle(color: SaynColors.paperText, fontSize: 13.5, height: 1.4),
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaynColors.paperCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'About SAYN',
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
            color: SaynColors.wineMaroon,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'SAYN v1.1.5',
              style: TextStyle(fontWeight: FontWeight.w800, color: SaynColors.wineMaroon),
            ),
            SizedBox(height: 6),
            Text(
              'Turn your voice into better writing. Real-time grammar polishing, Samsung One UI sliding trackpad keyboard, and floating voice assistant.',
              style: TextStyle(color: SaynColors.paperText, fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              '© 2026 SAYN AI Systems. All rights reserved.',
              style: TextStyle(color: SaynColors.paperTextMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: SaynColors.wineMaroon, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
