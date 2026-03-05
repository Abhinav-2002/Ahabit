import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/widget_helper.dart';

class FocusScreen extends StatefulWidget {
  final Habit habit;
  const FocusScreen({Key? key, required this.habit}) : super(key: key);

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin {
  int _totalSeconds = 25 * 60;
  int _remaining = 25 * 60;
  bool _running = false;
  Timer? _timer;
  int _sessionsToday = 0;
  int _sessionNumber = 1;
  late AnimationController _ringController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _selectedSound = 'none';
  bool _soundLoading = false;

  final List<Map<String, dynamic>> _presets = [
    {'label': '5 min', 'seconds': 300},
    {'label': '10 min', 'seconds': 600},
    {'label': '15 min', 'seconds': 900},
    {'label': '25 min', 'seconds': 1500},
    {'label': '45 min', 'seconds': 2700},
    {'label': '60 min', 'seconds': 3600},
  ];

  // Free CC0 ambient sound URLs (Pixabay CDN — royalty free, no auth)
  static const Map<String, String> _soundUrls = {
    'rain': 'https://cdn.pixabay.com/audio/2025/11/15/audio_c5116879e1.mp3',
    'ocean': 'https://cdn.pixabay.com/audio/2022/06/07/audio_b9bd4170e4.mp3',
    'forest': 'https://cdn.pixabay.com/audio/2025/04/07/audio_55a11bf51c.mp3',
    'cafe': 'https://cdn.pixabay.com/audio/2022/02/07/audio_0193462871.mp3',
    'fire': 'https://cdn.pixabay.com/audio/2026/01/16/audio_9b2a34b5c3.mp3',
  };

  static const List<Color> _habitColors = [
    Color(0xFFADD8F7),
    Color(0xFFFFB3C6),
    Color(0xFFD4B8F0),
    Color(0xFFB8F0C8),
    Color(0xFFFFF0B8),
    Color(0xFFFFCBA8),
  ];

  Color get _habitColor =>
      _habitColors[widget.habit.colorIndex % _habitColors.length];

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
    _loadSessionsToday();
  }

  void _loadSessionsToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'focus_sessions_${widget.habit.id}_$today';
    if (mounted) {
      setState(() {
        _sessionsToday = prefs.getInt(key) ?? 0;
      });
    }
  }

  void _startTimer() {
    setState(() => _running = true);
    _playSound();
    _ringController.duration = Duration(seconds: _totalSeconds);
    _ringController.forward(from: 1 - (_remaining / _totalSeconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 0) {
        _onTimerComplete();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _ringController.stop();
    _audioPlayer.pause();
    setState(() => _running = false);
  }

  void _stopTimer() {
    _timer?.cancel();
    _ringController.reset();
    _audioPlayer.stop();
    setState(() {
      _running = false;
      _remaining = _totalSeconds;
    });
  }

  void _onTimerComplete() async {
    _timer?.cancel();
    _audioPlayer.stop();
    _ringController.reset();
    setState(() => _running = false);

    HapticFeedback.heavyImpact();

    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'focus_sessions_${widget.habit.id}_$today';
    final count = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, count);
    if (mounted) {
      setState(() {
        _sessionsToday = count;
        _sessionNumber++;
      });
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              const Text('Focus Complete!',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  )),
              const SizedBox(height: 8),
              Text(
                '${_formatTime(_totalSeconds)} focused on\n'
                '${widget.habit.icon} ${widget.habit.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              const Text('Mark habit as done?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _markHabitDone();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('✅ Yes!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _remaining = _totalSeconds);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('Not yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _markHabitDone() {
    final logsBox = Hive.box<HabitLog>('habitLogs');
    final today = DateTime.now();

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final existingIndex = logsBox.values
        .toList()
        .indexWhere((l) => l.habitId == widget.habit.id && isSameDay(l.date, today));

    if (existingIndex < 0) {
      logsBox.add(HabitLog(
        habitId: widget.habit.id,
        date: today,
        isPunched: true,
        completedAt: DateTime.now(),
      ));
    } else {
      final log = logsBox.getAt(existingIndex)!;
      log.isPunched = true;
      log.completedAt = DateTime.now();
      log.save();
    }

    // Update widget immediately
    WidgetHelper.triggerWidgetUpdate();
  }

  Future<void> _playSound() async {
    if (_selectedSound == 'none') return;
    final url = _soundUrls[_selectedSound];
    if (url == null) return;
    try {
      setState(() => _soundLoading = true);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource(url));
      if (mounted) setState(() => _soundLoading = false);
    } on PlatformException catch (e) {
      // Log platform-specific errors (missing permissions, network issues, etc.)
      debugPrint('AUDIO ERROR [PlatformException]: code=${e.code}, message=${e.message}, details=${e.details}');
      if (mounted) setState(() => _soundLoading = false);
    } catch (e, st) {
      debugPrint('AUDIO ERROR [${e.runtimeType}]: $e');
      debugPrint('Stack: $st');
      if (mounted) setState(() => _soundLoading = false);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1 - (_remaining / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F7);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF111111);

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _stopTimer();
        return true;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _stopTimer();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_ios_new,
                            size: 16, color: textColor),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(widget.habit.icon,
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 4),
                          Text(widget.habit.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: textColor,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Circular ring timer ──
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 14,
                        backgroundColor: _habitColor.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(_habitColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(_remaining),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        Text(
                          _running ? 'focusing...' : 'ready',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Session info ──
              Text(
                'Session $_sessionNumber  •  $_sessionsToday done today',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // ── Timer presets ──
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _presets.length,
                  itemBuilder: (_, i) {
                    final p = _presets[i];
                    final selected = _totalSeconds == p['seconds'];
                    return GestureDetector(
                      onTap: _running
                          ? null
                          : () {
                              setState(() {
                                _totalSeconds = p['seconds'] as int;
                                _remaining = p['seconds'] as int;
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? _habitColor : cardColor,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color:
                                selected ? _habitColor : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(p['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : Colors.grey,
                            )),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ── Ambient sounds ──
              if (_soundLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 14, width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              SizedBox(
                height: 68,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    {'label': 'None', 'icon': '🔇', 'key': 'none'},
                    {'label': 'Rain', 'icon': '🌧️', 'key': 'rain'},
                    {'label': 'Ocean', 'icon': '🌊', 'key': 'ocean'},
                    {'label': 'Forest', 'icon': '🌿', 'key': 'forest'},
                    {'label': 'Cafe', 'icon': '☕', 'key': 'cafe'},
                    {'label': 'Fire', 'icon': '🔥', 'key': 'fire'},
                  ].map((s) {
                    final selected = _selectedSound == s['key'];
                    return GestureDetector(
                      onTap: () {
                        final newKey = s['key'] as String;
                        if (newKey == 'none') {
                          _audioPlayer.stop();
                          setState(() => _selectedSound = 'none');
                        } else {
                          setState(() => _selectedSound = newKey);
                          if (_running) {
                            _audioPlayer.stop();
                            _playSound();
                          }
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: selected
                              ? _habitColor.withOpacity(0.2)
                              : cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                selected ? _habitColor : Colors.grey.shade200,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(s['icon']!,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 2),
                            Text(s['label']!,
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey,
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Spacer(),

              // ── Buttons ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _running ? _pauseTimer : _startTimer,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: _running ? Colors.transparent : Colors.black,
                          borderRadius: BorderRadius.circular(50),
                          border: _running
                              ? Border.all(
                                  color: Colors.grey.shade300, width: 2)
                              : null,
                          boxShadow: _running
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Text(
                            _running ? '⏸  Pause' : '▶  Start Focus',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: _running ? Colors.grey : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_running || _remaining < _totalSeconds) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _stopTimer,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: const Text('⏹  Stop Session',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
