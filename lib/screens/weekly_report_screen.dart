import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../providers/habit_provider.dart';
import '../utils/habit_utils.dart';

class WeeklyReportScreen extends StatefulWidget {
  final DateTime weekStart;
  const WeeklyReportScreen({super.key, required this.weekStart});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final GlobalKey _reportKey = GlobalKey();
  late Map<String, dynamic> _reportData;
  bool _isLoading = true;

  final List<Color> _habitColors = [
    const Color(0xFFFF6B8A), // Pink
    const Color(0xFFFF9F43), // Orange
    const Color(0xFF4CAF50), // Green
    const Color(0xFF2196F3), // Blue
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFE91E63), // Magenta
    const Color(0xFF8BC34A), // Light Green
  ];

  @override
  void initState() {
    super.initState();
    _generateReportData();
  }

  Future<void> _generateReportData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'You';

    final habitsBox = Hive.box<Habit>('habits');
    final recordsBox = Hive.box<HabitLog>('habitLogs');

    final weekEnd = widget.weekStart.add(const Duration(days: 6));
    final weekDays = List.generate(7, (i) => widget.weekStart.add(Duration(days: i)));

    final habits = habitsBox.values.where((h) => !h.isHidden).toList();

    int totalPossible = habits.length * 7;
    int totalDone = 0;

    final habitStats = <Map<String, dynamic>>[];
    for (int i = 0; i < habits.length; i++) {
      final habit = habits[i];
      int doneDays = 0;

      for (final day in weekDays) {
        final normalizedDay = DateTime(day.year, day.month, day.day);

        // Check if habit existed on this day
        if (!habitExistedOnDate(habit, normalizedDay)) {
          totalPossible--; // Adjust total possible since this habit didn't exist yet
          continue;
        }

        try {
          final record = recordsBox.values.firstWhere(
            (r) => r.habitId == habit.id &&
                r.date.year == normalizedDay.year &&
                r.date.month == normalizedDay.month &&
                r.date.day == normalizedDay.day &&
                r.isPunched,
          );
          if (record != null) doneDays++;
        } catch (e) {
          // No record found for this day
        }
      }

      totalDone += doneDays;
      // Adjust percentage calculation to only count days the habit existed
      final habitPossibleDays = weekDays.where((d) => habitExistedOnDate(habit, DateTime(d.year, d.month, d.day))).length;
      final pct = habitPossibleDays == 0 ? 0 : (doneDays / habitPossibleDays * 100).round();

      habitStats.add({
        'habit': habit,
        'doneDays': doneDays,
        'percentage': pct,
        'status': pct == 100 ? '✅' : pct >= 70 ? '⚠️' : '❌',
        'statusColor': pct == 100
            ? const Color(0xFF4CAF50)
            : pct >= 70
                ? const Color(0xFFFF9F43)
                : const Color(0xFFFF6B8A),
        'colorIndex': i,
      });
    }

    final overallPct = totalPossible > 0 ? (totalDone / totalPossible * 100).round() : 0;

    int stars = overallPct >= 90
        ? 5
        : overallPct >= 75
            ? 4
            : overallPct >= 60
                ? 3
                : overallPct >= 40
                    ? 2
                    : 1;

    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final streak = habitProvider.calculateCurrentStreak();
    final rank = habitProvider.getRank();

    setState(() {
      _reportData = {
        'userName': userName,
        'weekStart': widget.weekStart,
        'weekEnd': weekEnd,
        'overallPct': overallPct,
        'stars': stars,
        'habitStats': habitStats,
        'totalDone': totalDone,
        'totalPossible': totalPossible,
        'streak': streak,
        'rank': rank,
      };
      _isLoading = false;
    });
  }



  String _formatDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  Future<void> _shareReport({String platform = 'general'}) async {
    try {
      final RenderRepaintBoundary boundary = _reportKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/habit_report.png');
      await file.writeAsBytes(pngBytes);

      String shareText = '';
      if (platform == 'whatsapp') {
        shareText = '🔥 My weekly habit report! I completed ${_reportData['overallPct']}% of my habits this week. #HabitPunch';
      } else if (platform == 'instagram') {
        shareText = '🔥 Weekly habit check-in! ${_reportData['overallPct']}% complete ⭐${_reportData['stars']} #HabitPunch #WeeklyReport';
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  Future<void> _saveToGallery() async {
    try {
      final RenderRepaintBoundary boundary = _reportKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      await Gal.putImageBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report saved to gallery! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Weekly Report',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: _isLoading ? null : () => _shareReport(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _reportKey,
                    child: _buildReportCard(isDark),
                  ),
                  const SizedBox(height: 24),
                  _buildShareButton(
                    icon: '📸',
                    label: 'Share to Instagram',
                    color: const Color(0xFFE1306C),
                    onTap: () => _shareReport(platform: 'instagram'),
                  ),
                  const SizedBox(height: 12),
                  _buildShareButton(
                    icon: '💬',
                    label: 'Share to WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () => _shareReport(platform: 'whatsapp'),
                  ),
                  const SizedBox(height: 12),
                  _buildShareButton(
                    icon: '🖼️',
                    label: 'Save to Gallery',
                    color: Colors.black,
                    onTap: _saveToGallery,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReportCard(bool isDark) {
    final habitStats = _reportData['habitStats'] as List<Map<String, dynamic>>;
    final stars = _reportData['stars'] as int;
    final weekEnd = _reportData['weekEnd'] as DateTime;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B8A),
            Color(0xFFFF9F43),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B8A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Text(
                    '🔥 YOUR WEEK IN HABITS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF6B8A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(_reportData['weekStart'])} — ${_formatDate(weekEnd)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),

            // User name + stars
            Text(
              '${_reportData['userName']}\'s Habit Report',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (i) => Text(
                    i < stars ? '⭐' : '☆',
                    style: const TextStyle(fontSize: 18, color: Color(0xFFFFD700)),
                  )),
            ),
            const SizedBox(height: 16),

            // Overall score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Score',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${_reportData['overallPct']}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Color(0xFFFF6B8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_reportData['overallPct'] as int) / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B8A)),
              ),
            ),
            const SizedBox(height: 20),

            // Per habit stats
            ...habitStats.map((stat) {
              final habit = stat['habit'] as Habit;
              final pct = stat['percentage'] as int;
              final colorIndex = stat['colorIndex'] as int;
              final color = _habitColors[colorIndex % _habitColors.length];
              final statusColor = stat['statusColor'] as Color;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          habit.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            habit.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${stat['status']} $pct%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 6,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),

            // Bottom stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('🔥', '${_reportData['streak']}', 'Best Streak'),
                _buildStatChip('⚡', '${_reportData['totalDone']}', 'Total Done'),
                _buildStatChip('🏆', '${_reportData['rank']}', 'Rank'),
              ],
            ),
            const SizedBox(height: 16),

            // Watermark
            Center(
              child: Text(
                'HabitPunch App',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            '$icon  $label',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
