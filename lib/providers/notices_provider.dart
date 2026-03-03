import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/notice.dart';

class NoticesProvider extends ChangeNotifier {
  final Box<Notice> _noticesBox = Hive.box<Notice>('notices');
  final _uuid = const Uuid();

  List<Notice> get notices {
    final list = _noticesBox.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Notice> get unreadNotices => notices.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotices.length;

  Future<void> addNotice({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final notice = Notice(
      id: _uuid.v4(),
      title: title,
      message: message,
      createdAt: DateTime.now(),
      isRead: false,
      type: type,
      data: data,
    );
    await _noticesBox.put(notice.id, notice);
    notifyListeners();
  }

  Future<void> markAsRead(String noticeId) async {
    final notice = _noticesBox.get(noticeId);
    if (notice != null) {
      notice.isRead = true;
      await notice.save();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (final notice in _noticesBox.values) {
      if (!notice.isRead) {
        notice.isRead = true;
        await notice.save();
      }
    }
    notifyListeners();
  }

  Future<void> deleteNotice(String noticeId) async {
    await _noticesBox.delete(noticeId);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _noticesBox.clear();
    notifyListeners();
  }

  // Check if notice of same type exists from today
  bool hasNoticeToday(String type) {
    final today = DateTime.now();
    return _noticesBox.values.any((n) =>
      n.type == type &&
      n.createdAt.year == today.year &&
      n.createdAt.month == today.month &&
      n.createdAt.day == today.day
    );
  }

  Future<void> addRankNotice(String rankName) async {
    if (hasNoticeToday('rank_$rankName')) return;
    
    await addNotice(
      title: '🏆 New Award!',
      message: 'You reached $rankName level!',
      type: 'rank_$rankName',
      data: {'rank': rankName},
    );
  }

  Future<void> addStreakNotice(int streakDays) async {
    await addNotice(
      title: '🔥 $streakDays Day Streak!',
      message: 'Keep going! You\'re building amazing habits!',
      type: 'streak',
      data: {'streak': streakDays},
    );
  }

  Future<void> addAllHabitsCompleteNotice(String date) async {
    await addNotice(
      title: '✅ All Habits Complete!',
      message: 'Great job! You completed all habits for $date',
      type: 'complete',
      data: {'date': date},
    );
  }
}
