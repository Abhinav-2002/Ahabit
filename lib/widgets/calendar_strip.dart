import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarStrip extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime? today;
  final Function(DateTime)? onDateSelected;
  final Map<DateTime, String>? dateStates; // 'complete', 'partial', or 'none'

  const CalendarStrip({
    super.key,
    this.selectedDate,
    this.today,
    this.onDateSelected,
    this.dateStates,
  });

  @override
  State<CalendarStrip> createState() => _CalendarStripState();
}

class _CalendarStripState extends State<CalendarStrip> {
  final ScrollController _scrollController = ScrollController();
  late DateTime _today;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    // Generate 7 days centered around today (3 before, today, 3 after)
    _weekDays = List.generate(7, (index) {
      return _today.add(Duration(days: index - 3));
    });
    
    // Auto-scroll to today after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    // Calculate position to center "today" in view
    const itemWidth = 56.0; // approximate width of each day pill
    const padding = 24.0; // horizontal padding
    final todayIndex = _weekDays.indexWhere((d) => _isSameDay(d, _today));
    if (todayIndex != -1 && _scrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      final offset = (todayIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2) + padding;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isPastDay(DateTime date) {
    return date.isBefore(_today.subtract(const Duration(days: 1)));
  }

  bool _isToday(DateTime date) {
    final today = widget.today ?? _today;
    return _isSameDay(date, today);
  }

  bool _isFuture(DateTime date) {
    final today = widget.today ?? _today;
    final todayNormalized = DateTime(today.year, today.month, today.day);
    return date.isAfter(todayNormalized);
  }

  bool _isSelected(DateTime date) {
    if (widget.selectedDate == null) return false;
    return _isSameDay(date, widget.selectedDate!);
  }

  String _getDateState(DateTime date) {
    if (widget.dateStates == null) return 'none';
    final key = DateTime(date.year, date.month, date.day);
    return widget.dateStates![key] ?? 'none';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _weekDays.map((date) => _buildDayPill(date)).toList(),
        ),
      ),
    );
  }

  Widget _buildDayPill(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisDate = DateTime(date.year, date.month, date.day);
    
    final isToday = thisDate.isAtSameMomentAs(today);
    final isPast = thisDate.isBefore(today);
    final isFuture = thisDate.isAfter(today);
    
    // Check completed state for this date
    final dateState = _getDateState(date);

    // Color logic:
    // Today = Pink circle border, filled if complete, half if partial
    // Complete = Pink circle filled + Crown
    // Partial = Yellow circle half-filled
    // None = Grey empty circle
    // Future = No circle

    Color? fillColor;
    Color borderColor;
    Color textColor;
    bool showCrown = false;
    bool isHalfFilled = false;

    if (isToday) {
      if (dateState == 'complete') {
        fillColor = const Color(0xFFFF6B8A);
        borderColor = const Color(0xFFFF6B8A);
        textColor = Colors.white;
        showCrown = true;
      } else if (dateState == 'partial') {
        fillColor = const Color(0xFFFFCC00);
        borderColor = const Color(0xFFFF6B8A); // Keep pink border for today
        textColor = Colors.black87;
        isHalfFilled = true;
      } else {
        fillColor = null;
        borderColor = const Color(0xFFFF6B8A);
        textColor = const Color(0xFFFF6B8A);
      }
    } else if (isPast) {
      if (dateState == 'complete') {
        fillColor = const Color(0xFFFF6584);
        borderColor = const Color(0xFFFF6584);
        textColor = Colors.white;
        showCrown = true;
      } else if (dateState == 'partial') {
        fillColor = const Color(0xFFFFCC00);
        borderColor = const Color(0xFFFFCC00);
        textColor = Colors.black87;
        isHalfFilled = true;
      } else {
        fillColor = null;
        borderColor = const Color(0xFFE0E0E0);
        textColor = const Color(0xFFBBBBBB);
      }
    } else {
      // Future
      fillColor = null;
      borderColor = Colors.transparent;
      textColor = const Color(0xFFCCCCCC);
    }

    return GestureDetector(
      onTap: isFuture ? null : () => widget.onDateSelected?.call(date),
      child: Container(
        width: 44,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('E').format(date).substring(0, 2), // Sa Su Mo Tu We Th Fr
              style: TextStyle(
                fontSize: 10,
                color: isToday
                  ? const Color(0xFFFF6B8A)
                  : Colors.grey.shade400,
                fontWeight: isToday
                  ? FontWeight.w800
                  : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !isHalfFilled ? fillColor ?? Colors.transparent : Colors.transparent,
                    border: Border.all(
                      color: borderColor,
                      width: isFuture ? 0 : 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Stack(
                      children: [
                        if (isHalfFilled)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 18, // Half height
                            child: Container(
                              color: fillColor,
                            ),
                          ),
                        Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showCrown)
                  Positioned(
                    top: -13,
                    child: const Text(
                      '👑',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
