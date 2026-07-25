import 'package:flutter/material.dart';

class ExpenseTag {
  const ExpenseTag({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
  });

  final String id;
  final String name;
  final IconData icon;
  final int colorValue;

  int get iconCodePoint {
    return icon.codePoint;
  }

  Color get color {
    return Color(colorValue);
  }

  ExpenseTag copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? colorValue,
  }) {
    return ExpenseTag(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

class TagIconOption {
  const TagIconOption({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;
}

const int maxExpenseTagCount = 8;

List<ExpenseTag> defaultExpenseTags() {
  return const <ExpenseTag>[
    ExpenseTag(
      id: 'home',
      name: 'Home',
      icon: Icons.home_rounded,
      colorValue: 0xFF00838F,
    ),
    ExpenseTag(
      id: 'bills',
      name: 'Bills',
      icon: Icons.receipt_long_rounded,
      colorValue: 0xFF6A1B9A,
    ),
    ExpenseTag(
      id: 'groceries',
      name: 'Groceries',
      icon: Icons.local_grocery_store_rounded,
      colorValue: 0xFF2E7D32,
    ),
    ExpenseTag(
      id: 'fun',
      name: 'Fun',
      icon: Icons.sports_esports_rounded,
      colorValue: 0xFF4527A0,
    ),
    ExpenseTag(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car_rounded,
      colorValue: 0xFF1565C0,
    ),
  ];
}

List<TagIconOption> tagIconOptions() {
  return const <TagIconOption>[
    TagIconOption(
      name: 'Tag',
      icon: Icons.sell_rounded,
    ),
    TagIconOption(
      name: 'Restaurant',
      icon: Icons.restaurant_rounded,
    ),
    TagIconOption(
      name: 'Groceries',
      icon: Icons.local_grocery_store_rounded,
    ),
    TagIconOption(
      name: 'Car',
      icon: Icons.directions_car_rounded,
    ),
    TagIconOption(
      name: 'Transit',
      icon: Icons.directions_bus_rounded,
    ),
    TagIconOption(
      name: 'Receipt',
      icon: Icons.receipt_long_rounded,
    ),
    TagIconOption(
      name: 'Home',
      icon: Icons.home_rounded,
    ),
    TagIconOption(
      name: 'Medical',
      icon: Icons.medical_services_rounded,
    ),
    TagIconOption(
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
    ),
    TagIconOption(
      name: 'Game',
      icon: Icons.sports_esports_rounded,
    ),
    TagIconOption(
      name: 'Flight',
      icon: Icons.flight_takeoff_rounded,
    ),
    TagIconOption(
      name: 'Coffee',
      icon: Icons.local_cafe_rounded,
    ),
    TagIconOption(
      name: 'Gift',
      icon: Icons.card_giftcard_rounded,
    ),
    TagIconOption(
      name: 'Fitness',
      icon: Icons.fitness_center_rounded,
    ),
    TagIconOption(
      name: 'School',
      icon: Icons.school_rounded,
    ),
    TagIconOption(
      name: 'Pet',
      icon: Icons.pets_rounded,
    ),
    TagIconOption(
      name: 'Phone',
      icon: Icons.phone_iphone_rounded,
    ),
    TagIconOption(
      name: 'Savings',
      icon: Icons.savings_rounded,
    ),
  ];
}
