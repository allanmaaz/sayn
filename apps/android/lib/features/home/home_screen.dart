import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/user_stats_service.dart';
import '../navigation/sayn_drawer.dart';

class HomeScreen extends StatelessWidget {
  final Function(int tabIndex)? onSwitchTab;
  final Function(String mode)? onSelectWritingTool;
  final Function(WritingNote note)? onOpenNote;

  const HomeScreen({
    super.key,
    this.onSwitchTab,
    this.onSelectWritingTool,
    this.onOpenNote,
  });

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final stats = UserStatsService.instance;

    return AnimatedBuilder(
      animation: stats,
      builder: (context, _) {
        return Scaffold(
      backgroundColor: SaynColors.paperBg,
      drawer: const SaynDrawer(),
      appBar: AppBar(
        backgroundColor: SaynColors.paperBg,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: SaynColors.wineMaroon, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: SaynColors.wineMaroon,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.graphic_eq_rounded,
                  color: SaynColors.warmCream,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'S A Y N',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                color: SaynColors.wineMaroon,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Generous bottom padding to avoid overlapping the floating bottom dock
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 1. DEEP MAROON HERO CARD ───
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    SaynColors.wineMaroon,
                    SaynColors.wineMaroonDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: SaynColors.wineMaroon.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Audio Wave Graphic on Right Side
                  Positioned(
                    right: 0,
                    top: 14,
                    bottom: 14,
                    child: _buildHeroWaveGraphic(),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTimeGreeting(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFEADECF),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 220,
                        child: Text(
                          'Turn your voice into better writing.',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Speak. Refine. Send.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFEADECF),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── 2. FOUR-STATISTICS OVERVIEW BAR ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: SaynColors.paperCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: SaynColors.paperBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.mic_none_rounded,
                    value: stats.wordsSpokenFormatted,
                    label: 'Words spoken',
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    icon: Icons.description_outlined,
                    value: stats.notesCreated.toString(),
                    label: 'Notes created',
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    icon: Icons.auto_awesome_outlined,
                    value: stats.textsPolished.toString(),
                    label: 'Texts polished',
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    icon: Icons.access_time_rounded,
                    value: stats.timeSavedFormatted,
                    label: 'Time saved',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── 3. RECENT VOICE NOTES SECTION (Dynamic Live Data) ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: SaynColors.wineMaroon,
                  ),
                ),
                InkWell(
                  onTap: () => onSwitchTab?.call(1), // go to studio
                  child: Row(
                    children: const [
                      Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: SaynColors.wineMaroon,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: SaynColors.wineMaroon),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (stats.recentEntries.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: SaynColors.paperCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SaynColors.paperBorder, width: 1),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.mic_none_rounded, color: SaynColors.wineMaroon, size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'No voice notes yet. Tap Voice below to start speaking in real time.',
                        style: TextStyle(fontSize: 13, color: SaynColors.paperTextMuted),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final note in stats.recentEntries.take(3)) ...[
                _buildRecentNoteCard(context, note: note),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 14),

            // ─── 4. WRITING TOOLS SECTION ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Writing tools',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: SaynColors.wineMaroon,
                  ),
                ),
                InkWell(
                  onTap: () => onSwitchTab?.call(1),
                  child: Row(
                    children: const [
                      Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: SaynColors.wineMaroon,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: SaynColors.wineMaroon),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    icon: Icons.description_outlined,
                    label: 'Paraphrase',
                    onTap: () {
                      onSelectWritingTool?.call('fluent');
                      onSwitchTab?.call(1);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildToolCard(
                    icon: Icons.verified_user_outlined,
                    label: 'Fix grammar',
                    onTap: () {
                      onSelectWritingTool?.call('standard');
                      onSwitchTab?.call(1);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildToolCard(
                    icon: Icons.format_list_bulleted_rounded,
                    label: 'Summarize',
                    onTap: () {
                      onSelectWritingTool?.call('shorten');
                      onSwitchTab?.call(1);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildToolCard(
                    icon: Icons.translate_rounded,
                    label: 'Translate',
                    onTap: () {
                      onSelectWritingTool?.call('natural');
                      onSwitchTab?.call(1);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
}

  Widget _buildHeroWaveGraphic() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildWaveBar(14, 0.4),
        const SizedBox(width: 4),
        _buildWaveBar(26, 0.65),
        const SizedBox(width: 4),
        _buildWaveBar(44, 0.95),
        const SizedBox(width: 4),
        _buildWaveBar(32, 0.8),
        const SizedBox(width: 4),
        _buildWaveBar(16, 0.5),
      ],
    );
  }

  Widget _buildWaveBar(double height, double opacity) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF5EBDD).withOpacity(opacity),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 19, color: SaynColors.wineMaroon),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: SaynColors.paperText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: SaynColors.paperTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 32, color: SaynColors.paperBorder);
  }

  Widget _buildRecentNoteCard(
    BuildContext context, {
    required WritingNote note,
  }) {
    return InkWell(
      onTap: () {
        if (onOpenNote != null) {
          onOpenNote!(note);
        } else {
          onSwitchTab?.call(1);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: SaynColors.paperCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SaynColors.paperBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SaynColors.paperSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                note.isVoice ? Icons.mic_none_rounded : Icons.description_outlined,
                color: SaynColors.wineMaroon,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: SaynColors.wineMaroon,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note.preview,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: SaynColors.paperTextMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              note.timeFormatted,
              style: const TextStyle(
                fontSize: 10.5,
                color: SaynColors.paperTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: SaynColors.paperTextMuted),
              color: SaynColors.paperCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'Open' && onOpenNote != null) {
                  onOpenNote!(note);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$val: ${note.title}'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: SaynColors.wineMaroon,
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'Open', child: Text('Open in Studio')),
                const PopupMenuItem(value: 'Copy', child: Text('Copy')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: SaynColors.paperCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SaynColors.paperBorder, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: SaynColors.wineMaroon, size: 21),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SaynColors.paperText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
