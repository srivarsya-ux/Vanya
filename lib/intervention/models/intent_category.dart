/// What the user is likely trying to do by opening a protected app.
/// Returned by Stage 1 (Intent Detection) of the AI decision pipeline.
enum IntentCategory {
  messaging,
  homework,
  research,
  work,
  shopping,
  banking,
  navigation,
  photography,
  emergency,
  habitScrolling,
  entertainment,
  other;

  String get label {
    switch (this) {
      case IntentCategory.messaging:
        return 'Messaging';
      case IntentCategory.homework:
        return 'Homework';
      case IntentCategory.research:
        return 'Research';
      case IntentCategory.work:
        return 'Work';
      case IntentCategory.shopping:
        return 'Shopping';
      case IntentCategory.banking:
        return 'Banking';
      case IntentCategory.navigation:
        return 'Navigation';
      case IntentCategory.photography:
        return 'Photography';
      case IntentCategory.emergency:
        return 'Emergency';
      case IntentCategory.habitScrolling:
        return 'Habit scrolling';
      case IntentCategory.entertainment:
        return 'Entertainment';
      case IntentCategory.other:
        return 'Other';
    }
  }

  static IntentCategory fromString(String value) {
    return IntentCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == value.toLowerCase().replaceAll(' ', '').replaceAll('_', ''),
      orElse: () => IntentCategory.other,
    );
  }
}
