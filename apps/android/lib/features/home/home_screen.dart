import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../services/user_stats_service.dart';
import '../navigation/sayn_drawer.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onSwitchTab;
  final Function(String mode)? onSelectWritingTool;
  final Function(WritingNote note)? onOpenNote;

  const HomeScreen({
    super.key,
    this.onSwitchTab,
    this.onSelectWritingTool,
    this.onOpenNote,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isHeroBannerVisible = true;

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
            if (_isHeroBannerVisible) ...[
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
                      right: 18,
                      top: 14,
                      bottom: 14,
                      child: _buildHeroWaveGraphic(),
                    ),
                    // Cross Dismiss Button (Top Right)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isHeroBannerVisible = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: Color(0xFFEADECF),
                            ),
                          ),
                        ),
                      ),
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
            ],

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

            // ─── 3. RECENT NOTES SECTION (Chronologically Grouped Full View) ───
            const Text(
              'Recent',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: SaynColors.wineMaroon,
              ),
            ),
            const SizedBox(height: 12),

            if (stats.allEntries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                decoration: BoxDecoration(
                  color: SaynColors.paperCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: SaynColors.paperBorder, width: 1),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: SaynColors.paperSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.mic_none_rounded, color: SaynColors.wineMaroon, size: 26),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No writing history yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SaynColors.wineMaroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your voice dictations and notes will appear here, organized by date and time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: SaynColors.paperTextMuted, height: 1.4),
                    ),
                  ],
                ),
              )
            else ...[
              Builder(
                builder: (context) {
                  final grouped = _groupNotes(stats.allEntries);
                  final List<Widget> sectionWidgets = [];

                  grouped.forEach((sectionTitle, notesList) {
                    sectionWidgets.add(
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: SaynColors.paperSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: SaynColors.paperBorder),
                              ),
                              child: Text(
                                sectionTitle.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: SaynColors.wineMaroon,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: SaynColors.paperBorder,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    for (final note in notesList) {
                      sectionWidgets.add(_buildRecentNoteCard(context, note: note));
                      sectionWidgets.add(const SizedBox(height: 10));
                    }
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sectionWidgets,
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
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
      onTap: () => _showNoteDetailSheet(context, note),
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
              _formatNoteTimestamp(note.createdAt),
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
              onSelected: (val) async {
                if (val == 'View') {
                  _showNoteDetailSheet(context, note);
                } else if (val == 'Open') {
                  if (widget.onOpenNote != null) {
                    widget.onOpenNote!(note);
                  } else {
                    widget.onSwitchTab?.call(1);
                  }
                } else if (val == 'Copy') {
                  Clipboard.setData(ClipboardData(text: note.resultText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                      backgroundColor: SaynColors.wineMaroon,
                    ),
                  );
                } else if (val == 'Delete') {
                  await UserStatsService.instance.deleteNote(note.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deleted "${note.title}"'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: SaynColors.wineMaroon,
                      ),
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'View', child: Text('View note')),
                const PopupMenuItem(value: 'Copy', child: Text('Copy text')),
                const PopupMenuItem(value: 'Open', child: Text('Open in Studio')),
                const PopupMenuItem(value: 'Delete', child: Text('Delete note')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDetailSheet(BuildContext context, WritingNote note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: SaynColors.paperBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SaynColors.paperBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: SaynColors.paperSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    note.isVoice ? Icons.mic_rounded : Icons.description_outlined,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: SaynColors.wineMaroon,
                        ),
                      ),
                      Text(
                        '${note.timeFormatted} • ${note.wordCount} words • ${note.mode}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: SaynColors.paperTextMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: SaynColors.paperTextMuted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 280),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SaynColors.paperCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SaynColors.paperBorder),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  note.resultText,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: SaynColors.paperText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: note.resultText));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                          backgroundColor: SaynColors.wineMaroon,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SaynColors.wineMaroon,
                      side: const BorderSide(color: SaynColors.paperBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (widget.onOpenNote != null) {
                        widget.onOpenNote!(note);
                      } else {
                        widget.onSwitchTab?.call(1);
                      }
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Open in Studio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SaynColors.wineMaroon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await UserStatsService.instance.deleteNote(note.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${note.title}"'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: SaynColors.wineMaroon,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: SaynColors.wineMaroon),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Map<String, List<WritingNote>> _groupNotes(List<WritingNote> notes) {
    final Map<String, List<WritingNote>> groups = {};
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    const monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    for (final note in notes) {
      final created = note.createdAt;
      String sectionKey;

      if (created.isAfter(todayStart) || now.difference(created).inHours < 24) {
        sectionKey = 'Today';
      } else if (created.isAfter(yesterdayStart)) {
        sectionKey = 'Yesterday';
      } else {
        final monthName = monthNames[created.month];
        sectionKey = '$monthName ${created.year}';
      }

      groups.putIfAbsent(sectionKey, () => []).add(note);
    }

    return groups;
  }

  String _formatNoteTimestamp(DateTime dt) {
    final now = DateTime.now();
    final isWithin24h = now.difference(dt).inHours < 24 && dt.day == now.day;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';

    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${monthNames[dt.month]} ${dt.day}';

    if (isWithin24h) {
      return '$dateStr • $timeStr';
    } else if (now.difference(dt).inDays <= 1 && dt.day == now.subtract(const Duration(days: 1)).day) {
      return 'Yesterday • $timeStr';
    } else {
      return '$dateStr • $timeStr';
    }
  }
}
