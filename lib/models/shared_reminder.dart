import 'reminder.dart';

enum ParticipantStatus {
  pending,
  accepted,
  declined,
}

class Participant {
  final String userId;
  final String name;
  final ParticipantStatus status;

  const Participant({
    required this.userId,
    required this.name,
    this.status = ParticipantStatus.pending,
  });

  Participant copyWith({
    ParticipantStatus? status,
  }) {
    return Participant(
      userId: userId,
      name: name,
      status: status ?? this.status,
    );
  }
}

class SharedReminder extends Reminder {
  final String createdBy;
  final String creatorName;
  final List<Participant> participants;

  const SharedReminder({
    required super.id,
    required super.title,
    super.description,
    required super.dateTime,
    super.alertBefore,
    super.repeat,
    super.category,
    super.status,
    required super.createdAt,
    required this.createdBy,
    required this.creatorName,
    required this.participants,
  });

  @override
  SharedReminder copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    ReminderAlert? alertBefore,
    ReminderRepeat? repeat,
    ReminderCategory? category,
    ReminderStatus? status,
    List<Participant>? participants,
  }) {
    return SharedReminder(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      alertBefore: alertBefore ?? this.alertBefore,
      repeat: repeat ?? this.repeat,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      creatorName: creatorName,
      participants: participants ?? this.participants,
    );
  }
}
