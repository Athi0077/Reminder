import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/reminder.dart';
import '../../models/shared_reminder.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/shared_reminder_provider.dart';
import '../../providers/selected_friends_provider.dart';
import '../../providers/friends_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../providers/settings_provider.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  final String? editReminderId;
  final String? initialFriendId;

  const CreateReminderScreen({super.key, this.editReminderId, this.initialFriendId});

  @override
  ConsumerState<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  ReminderCategory _selectedCategory = ReminderCategory.personal;
  ReminderRepeat _selectedRepeat = ReminderRepeat.doesNotRepeat;
  ReminderAlert _selectedAlert = ReminderAlert.tenMinutesBefore;
  
  bool _isSharedMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFriendId != null) {
      _isSharedMode = true;
    }
    
    // Set default alert from settings
    final defaultAlertString = ref.read(settingsProvider).defaultAlertTime;
    _selectedAlert = ReminderAlert.values.firstWhere(
      (a) => a.displayName.toLowerCase() == defaultAlertString.toLowerCase(),
      orElse: () => ReminderAlert.tenMinutesBefore,
    );
    
    Future.microtask(() {
      if (widget.initialFriendId != null) {
        final friend = ref.read(friendsProvider).cast().firstWhere((f) => f?.id == widget.initialFriendId, orElse: () => null);
        if (friend != null) {
          ref.read(selectedFriendsProvider.notifier).setFriends([friend]);
        }
      } else {
        ref.read(selectedFriendsProvider.notifier).clear();
      }

      if (widget.editReminderId != null) {
        final reminder = ref.read(reminderProvider).firstWhere(
              (r) => r.id == widget.editReminderId,
              orElse: () => throw Exception('Reminder not found'),
            );
        setState(() {
          _titleController.text = reminder.title;
          _descriptionController.text = reminder.description ?? '';
          _selectedDate = reminder.dateTime;
          _selectedTime = TimeOfDay.fromDateTime(reminder.dateTime);
          _selectedCategory = reminder.category;
          _selectedRepeat = reminder.repeat;
          _selectedAlert = reminder.alertBefore;
          _isSharedMode = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (!context.mounted) return;
      _selectTime(context);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showSelector<T>(String title, List<T> items, T currentValue, void Function(T) onSelected, String Function(T) getName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...items.map((item) {
                return ListTile(
                  title: Text(getName(item)),
                  trailing: item == currentValue ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    onSelected(item);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showFriendSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final friends = ref.watch(friendsProvider);
                final selectedFriends = ref.watch(selectedFriendsProvider);
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Select Friends', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search friends...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          final isSelected = selectedFriends.any((f) => f.id == friend.id);
                          return CheckboxListTile(
                            value: isSelected,
                            title: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(friend.name[0], style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                                ),
                                const SizedBox(width: 12),
                                Text(friend.name),
                              ],
                            ),
                            onChanged: (_) {
                              ref.read(selectedFriendsProvider.notifier).toggleFriend(friend);
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: AppButton(
                        text: 'Done (${selectedFriends.length})',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _saveReminder() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isSharedMode && ref.read(selectedFriendsProvider).isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one friend to share with.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final isEdit = widget.editReminderId != null;

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      if (_isSharedMode) {
        final selectedFriends = ref.read(selectedFriendsProvider);
        final participants = selectedFriends.map((f) => Participant(
          userId: f.id,
          name: f.name,
          status: ParticipantStatus.pending,
        )).toList();

        final sharedReminder = SharedReminder(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          dateTime: dateTime,
          alertBefore: _selectedAlert,
          repeat: _selectedRepeat,
          category: _selectedCategory,
          createdAt: DateTime.now(),
          createdBy: 'me',
          creatorName: 'Athi',
          participants: participants,
        );

        ref.read(sharedReminderProvider.notifier).createSharedReminder(
              sharedReminder,
              selectedFriends.map((f) => f.id).toList(),
            );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder shared successfully 🎉')),
        );
        context.go('/home');
      } else {
        final reminder = Reminder(
          id: isEdit ? widget.editReminderId! : DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          dateTime: dateTime,
          alertBefore: _selectedAlert,
          repeat: _selectedRepeat,
          category: _selectedCategory,
          createdAt: isEdit ? ref.read(reminderProvider).firstWhere((r) => r.id == widget.editReminderId).createdAt : DateTime.now(),
        );

        if (isEdit) {
          ref.read(reminderProvider.notifier).updateReminder(reminder);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder updated successfully.')),
          );
          context.pop();
        } else {
          ref.read(reminderProvider.notifier).addReminder(reminder);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder created successfully 🎉')),
          );
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editReminderId != null;
    final selectedFriends = ref.watch(selectedFriendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Reminder' : 'Create Reminder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isEdit) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSharedMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isSharedMode ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Personal',
                              style: TextStyle(
                                color: !_isSharedMode ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSharedMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isSharedMode ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Share with Friends',
                              style: TextStyle(
                                color: _isSharedMode ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              AppTextField(
                label: 'Reminder Title',
                hint: 'e.g. Project submission',
                controller: _titleController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                hint: 'Add more details...',
                controller: _descriptionController,
              ),
              const SizedBox(height: 24),

              if (_isSharedMode) ...[
                Text(
                  'Share with',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...selectedFriends.map((f) => Chip(
                      label: Text(f.name),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => ref.read(selectedFriendsProvider.notifier).toggleFriend(f),
                    )),
                    ActionChip(
                      label: const Text('Add Friends'),
                      avatar: const Icon(Icons.add, size: 16),
                      onPressed: _showFriendSelection,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              Text(
                'Date & Time',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('d MMM yyyy').format(_selectedDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Category',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReminderCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category.displayName),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                title: const Text('Alert'),
                subtitle: Text(_selectedAlert.displayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showSelector<ReminderAlert>(
                    'Alert',
                    ReminderAlert.values,
                    _selectedAlert,
                    (v) => setState(() => _selectedAlert = v),
                    (v) => v.displayName,
                  );
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.repeat, color: AppColors.textPrimary),
                title: const Text('Repeat'),
                subtitle: Text(_selectedRepeat.displayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showSelector<ReminderRepeat>(
                    'Repeat',
                    ReminderRepeat.values,
                    _selectedRepeat,
                    (v) => setState(() => _selectedRepeat = v),
                    (v) => v.displayName,
                  );
                },
              ),
              const SizedBox(height: 48),
              AppButton(
                text: isEdit ? 'Save Changes' : (_isSharedMode ? 'Create Shared Reminder' : 'Create Reminder'),
                isLoading: _isLoading,
                onPressed: _saveReminder,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
