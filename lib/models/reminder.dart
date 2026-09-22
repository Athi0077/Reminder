enum ReminderStatus {
  upcoming,
  completed,
  overdue,
}

enum ReminderCategory {
  personal,
  work,
  study,
  health,
  other,
}

enum ReminderRepeat {
  doesNotRepeat,
  everyDay,
  everyWeek,
  everyMonth,
  everyYear,
}

enum ReminderAlert {
  atTimeOfEvent,
  fiveMinutesBefore,
  tenMinutesBefore,
  fifteenMinutesBefore,
  thirtyMinutesBefore,
  oneHourBefore,
  oneDayBefore,
}

class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final ReminderAlert alertBefore;
  final ReminderRepeat repeat;
  final ReminderCategory category;
  final ReminderStatus status;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.alertBefore = ReminderAlert.tenMinutesBefore,
    this.repeat = ReminderRepeat.doesNotRepeat,
    this.category = ReminderCategory.personal,
    this.status = ReminderStatus.upcoming,
    required this.createdAt,
  });

  Reminder copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    ReminderAlert? alertBefore,
    ReminderRepeat? repeat,
    ReminderCategory? category,
    ReminderStatus? status,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      alertBefore: alertBefore ?? this.alertBefore,
      repeat: repeat ?? this.repeat,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

extension ReminderCategoryExtension on ReminderCategory {
  String get displayName {
    switch (this) {
      case ReminderCategory.personal:
        return 'Personal';
      case ReminderCategory.work:
        return 'Work';
      case ReminderCategory.study:
        return 'Study';
      case ReminderCategory.health:
        return 'Health';
      case ReminderCategory.other:
        return 'Other';
    }
  }
}

extension ReminderAlertExtension on ReminderAlert {
  String get displayName {
    switch (this) {
      case ReminderAlert.atTimeOfEvent:
        return 'At time of event';
      case ReminderAlert.fiveMinutesBefore:
        return '5 minutes before';
      case ReminderAlert.tenMinutesBefore:
        return '10 minutes before';
      case ReminderAlert.fifteenMinutesBefore:
        return '15 minutes before';
      case ReminderAlert.thirtyMinutesBefore:
        return '30 minutes before';
      case ReminderAlert.oneHourBefore:
        return '1 hour before';
      case ReminderAlert.oneDayBefore:
        return '1 day before';
    }
  }
}

extension ReminderRepeatExtension on ReminderRepeat {
  String get displayName {
    switch (this) {
      case ReminderRepeat.doesNotRepeat:
        return 'Does not repeat';
      case ReminderRepeat.everyDay:
        return 'Every day';
      case ReminderRepeat.everyWeek:
        return 'Every week';
      case ReminderRepeat.everyMonth:
        return 'Every month';
      case ReminderRepeat.everyYear:
        return 'Every year';
    }
  }
}
