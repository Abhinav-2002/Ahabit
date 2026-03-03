import 'package:flutter/material.dart';

class HabitTemplate {
  final String name;
  final String icon;
  final String goalType;
  final double goal;
  final String unit;
  final String frequency;

  const HabitTemplate({
    required this.name,
    required this.icon,
    required this.goalType,
    required this.goal,
    this.unit = '',
    this.frequency = 'daily',
  });
}

class TemplatePack {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<HabitTemplate> habits;
  final Color primaryColor;
  final Color secondaryColor;

  const TemplatePack({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.habits,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

const List<Color> habitColors = [
  Color(0xFFFF6584), // Pink
  Color(0xFFFF9F43), // Orange
  Color(0xFF4CAF50), // Green
  Color(0xFF4DABF7), // Blue
  Color(0xFF845EF7), // Purple
  Color(0xFFF9E14B), // Yellow
  Color(0xFFC8F53C), // Lime
  Color(0xFF20C997), // Teal
  Color(0xFFFF6B6B), // Red
  Color(0xFF6C757D), // Gray
];

const List<TemplatePack> habitTemplatePacks = [
  TemplatePack(
    id: 'fitness',
    name: 'Fitness Pack',
    emoji: '💪',
    description: 'Build your perfect fitness routine',
    primaryColor: Color(0xFFADD8F7),
    secondaryColor: Color(0xFFB8F0C8),
    habits: [
      HabitTemplate(
        name: 'Morning Workout',
        icon: '💪',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'Drink Water',
        icon: '💧',
        goalType: 'quantity',
        goal: 3000,
        unit: 'ml',
      ),
      HabitTemplate(
        name: '10k Steps',
        icon: '🏃',
        goalType: 'quantity',
        goal: 10000,
        unit: 'steps',
      ),
      HabitTemplate(
        name: 'Sleep 8 Hours',
        icon: '😴',
        goalType: 'duration',
        goal: 480,
        unit: 'min',
      ),
      HabitTemplate(
        name: 'Eat Healthy',
        icon: '🥗',
        goalType: 'count',
        goal: 1,
      ),
    ],
  ),
  TemplatePack(
    id: 'student',
    name: 'Student Pack',
    emoji: '📚',
    description: 'Stay focused and study smarter',
    primaryColor: Color(0xFFD4B8F0),
    secondaryColor: Color(0xFFFFF0B8),
    habits: [
      HabitTemplate(
        name: 'Study Session',
        icon: '📖',
        goalType: 'duration',
        goal: 120,
        unit: 'min',
      ),
      HabitTemplate(
        name: 'Read 30 mins',
        icon: '📚',
        goalType: 'duration',
        goal: 30,
        unit: 'min',
      ),
      HabitTemplate(
        name: 'No Phone 2hrs',
        icon: '📵',
        goalType: 'duration',
        goal: 120,
        unit: 'min',
      ),
      HabitTemplate(
        name: 'Sleep by 11 PM',
        icon: '🌙',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'Practice Writing',
        icon: '✍️',
        goalType: 'count',
        goal: 1,
      ),
    ],
  ),
  TemplatePack(
    id: 'money',
    name: 'Money Pack',
    emoji: '💰',
    description: 'Build healthy financial habits',
    primaryColor: Color(0xFFFFF0B8),
    secondaryColor: Color(0xFFFFCBA8),
    habits: [
      HabitTemplate(
        name: 'Save ₹100',
        icon: '💰',
        goalType: 'quantity',
        goal: 100,
        unit: '₹',
      ),
      HabitTemplate(
        name: 'No Impulse Buy',
        icon: '🚫',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'Track Expenses',
        icon: '📊',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'No Eating Out',
        icon: '☕',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'Check Balance',
        icon: '💳',
        goalType: 'count',
        goal: 1,
      ),
    ],
  ),
  TemplatePack(
    id: 'wellness',
    name: 'Wellness Pack',
    emoji: '🧘',
    description: 'Take care of your mind and body',
    primaryColor: Color(0xFFFFB3C6),
    secondaryColor: Color(0xFFB8F0C8),
    habits: [
      HabitTemplate(
        name: 'Meditate',
        icon: '🧘',
        goalType: 'duration',
        goal: 10,
        unit: 'min',
      ),
      HabitTemplate(
        name: 'Journal',
        icon: '📔',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'Gratitude',
        icon: '🙏',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'Evening Walk',
        icon: '🚶',
        goalType: 'duration',
        goal: 20,
        unit: 'min',
      ),
      HabitTemplate(
        name: 'No Social Media',
        icon: '🌿',
        goalType: 'duration',
        goal: 60,
        unit: 'min',
      ),
    ],
  ),
  TemplatePack(
    id: 'morning',
    name: 'Morning Routine',
    emoji: '🌅',
    description: 'Win the morning, win the day',
    primaryColor: Color(0xFFFFCBA8),
    secondaryColor: Color(0xFFFFF0B8),
    habits: [
      HabitTemplate(
        name: 'Wake by 6 AM',
        icon: '⏰',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'Cold Shower',
        icon: '🚿',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'Meditate 5 min',
        icon: '🧘',
        goalType: 'duration',
        goal: 5,
        unit: 'min',
      ),
      HabitTemplate(
        name: 'Morning Journal',
        icon: '📔',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'No Phone 1hr',
        icon: '☀️',
        goalType: 'duration',
        goal: 60,
        unit: 'min',
      ),
    ],
  ),
  TemplatePack(
    id: 'night',
    name: 'Night Routine',
    emoji: '🌙',
    description: 'End your day with intention',
    primaryColor: Color(0xFFD4B8F0),
    secondaryColor: Color(0xFFADD8F7),
    habits: [
      HabitTemplate(
        name: 'Screen Off 9 PM',
        icon: '📵',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'Read Before Bed',
        icon: '📚',
        goalType: 'duration',
        goal: 20,
        unit: 'min',
      ),
      HabitTemplate(
        name: 'Skincare',
        icon: '🪥',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'Reflect & Journal',
        icon: '📔',
        goalType: 'count',
        goal: 1,
      ),
      HabitTemplate(
        name: 'Sleep by 10:30',
        icon: '😴',
        goalType: 'count',
        goal: 1,
      ),
    ],
  ),
];
