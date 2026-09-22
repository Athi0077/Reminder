import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/shared_reminder_provider.dart';
import '../../models/reminder.dart';
import '../home/widgets/reminder_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Reminder> _getEventsForDay(DateTime day, List<Reminder> personal, List<Reminder> shared) {
    final allEvents = [...personal, ...shared];
    return allEvents.where((r) => isSameDay(r.dateTime, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final personalReminders = ref.watch(reminderProvider);
    final sharedReminders = ref.watch(sharedReminderProvider);
    
    // We cast shared reminders to Reminder for the shared widget list display
    final List<Reminder> castedShared = sharedReminders.map((s) => Reminder(
      id: s.id,
      title: s.title,
      description: s.description,
      dateTime: s.dateTime,
      alertBefore: s.alertBefore,
      repeat: s.repeat,
      category: s.category,
      createdAt: s.createdAt,
      status: s.status,
    )).toList();

    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!, personalReminders, castedShared) : <Reminder>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar<Reminder>(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) => _getEventsForDay(day, personalReminders, castedShared),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Text(
                      'No reminders for ${DateFormat.yMMMd().format(_selectedDay!)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final reminder = selectedEvents[index];
                      // We need a way to pass original shared reminders if it was shared.
                      // Since we casted it, we lose the shared specifics in the card.
                      // Let's just find it back from original lists.
                      final originalShared = sharedReminders.where((s) => s.id == reminder.id).firstOrNull;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ReminderCard(reminder: originalShared ?? reminder),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
