const Reminder = require('../models/Reminder');
const FriendRequest = require('../models/FriendRequest');
const Notification = require('../models/Notification');

// Get all personal reminders for the user
const getReminders = async (req, res) => {
  try {
    const reminders = await Reminder.find({ createdBy: req.user.id, isShared: false })
      .sort('dateTime');
    res.json({ success: true, data: reminders });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// Create personal reminder
const createReminder = async (req, res) => {
  try {
    const { title, description, dateTime, alertBefore, repeat, category } = req.body;

    const reminder = await Reminder.create({
      title,
      description,
      dateTime,
      alertBefore,
      repeat,
      category,
      createdBy: req.user.id,
      isShared: false,
    });

    res.status(201).json({ success: true, data: reminder });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// Update personal or shared reminder (creator only)
const updateReminder = async (req, res) => {
  try {
    const reminder = await Reminder.findById(req.params.id);

    if (!reminder) {
      return res.status(404).json({ success: false, message: 'Reminder not found' });
    }

    if (reminder.createdBy.toString() !== req.user.id) {
      return res.status(401).json({ success: false, message: 'Not authorized to update this reminder' });
    }

    const updatedReminder = await Reminder.findByIdAndUpdate(req.params.id, req.body, { new: true });
    
    if (updatedReminder.isShared) {
      const populatedReminder = await Reminder.findById(updatedReminder._id)
        .populate('createdBy', 'name email avatar')
        .populate('participants.userId', 'name');
        
      const formatted = populatedReminder.toJSON();
      formatted.creatorName = req.user.name;
      formatted.createdBy = req.user.id;
      formatted.participants = formatted.participants.map(p => ({
        userId: p.userId._id,
        status: p.status,
        name: p.userId.name
      }));

      const io = req.app.get('io');
      if (io) {
        formatted.participants.forEach(p => {
          io.to(`user:${p.userId}`).emit('event_updated', formatted);
        });
      }
    }
    
    res.json({ success: true, data: updatedReminder });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// Delete reminder (creator only)
const deleteReminder = async (req, res) => {
  try {
    const reminder = await Reminder.findById(req.params.id);

    if (!reminder) {
      return res.status(404).json({ success: false, message: 'Reminder not found' });
    }

    if (reminder.createdBy.toString() !== req.user.id) {
      return res.status(401).json({ success: false, message: 'Not authorized to delete this reminder' });
    }

    await reminder.deleteOne();
    res.json({ success: true, message: 'Reminder removed' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// Complete a personal reminder
const completeReminder = async (req, res) => {
  try {
    const reminder = await Reminder.findById(req.params.id);

    if (!reminder) {
      return res.status(404).json({ success: false, message: 'Reminder not found' });
    }

    if (reminder.createdBy.toString() !== req.user.id) {
      return res.status(401).json({ success: false, message: 'Not authorized' });
    }

    reminder.status = 'completed';
    await reminder.save();

    res.json({ success: true, data: reminder });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// Get shared reminders where user is a participant (shared with me)
const getSharedWithMe = async (req, res) => {
  try {
    const reminders = await Reminder.find({
      isShared: true,
      createdBy: { $ne: req.user.id },
      'participants.userId': req.user.id
    })
    .populate('createdBy', 'name email avatar')
    .sort('dateTime');
    
    // Add creatorName virtually for convenience in the app
    const formatted = reminders.map(r => {
      const obj = r.toJSON();
      obj.creatorName = r.createdBy.name;
      obj.createdBy = r.createdBy._id; // Restore ID form for consistency
      return obj;
    });

    res.json({ success: true, data: formatted });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// Get shared reminders created by the user (shared by me)
const getSharedByMe = async (req, res) => {
  try {
    const reminders = await Reminder.find({
      isShared: true,
      createdBy: req.user.id,
    })
    .populate('participants.userId', 'name')
    .sort('dateTime');

    // Add participant names for convenience
    const formatted = reminders.map(r => {
      const obj = r.toJSON();
      obj.creatorName = req.user.name; // I am the creator
      
      // Update participant names
      obj.participants = obj.participants.map(p => {
        return {
          userId: p.userId._id,
          status: p.status,
          name: p.userId.name
        };
      });
      return obj;
    });

    res.json({ success: true, data: formatted });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// Create shared reminder
const createSharedReminder = async (req, res) => {
  try {
    const { title, description, dateTime, alertBefore, repeat, category, participants } = req.body;

    if (!participants || participants.length === 0) {
      return res.status(400).json({ success: false, message: 'Participants required for shared reminder' });
    }

    // Verify all participants are friends
    for (let p of participants) {
      const isFriend = await FriendRequest.findOne({
        status: 'accepted',
        $or: [
          { sender: req.user.id, receiver: p.userId },
          { sender: p.userId, receiver: req.user.id }
        ]
      });
      
      if (!isFriend) {
        return res.status(400).json({ success: false, message: 'Can only share with friends' });
      }
    }

    const participantData = participants.map(p => ({
      userId: p.userId,
      status: 'pending',
    }));

    const reminder = await Reminder.create({
      title,
      description,
      dateTime,
      alertBefore,
      repeat,
      category,
      createdBy: req.user.id,
      isShared: true,
      participants: participantData,
    });

    // Create notifications for all participants
    const notifications = participants.map(p => ({
      recipient: p.userId,
      sender: req.user.id,
      type: 'reminder_shared',
      title: 'New Shared Reminder',
      message: `${req.user.name || 'A friend'} shared a reminder: "${title}"`,
      relatedId: reminder._id,
    }));
    
    const io = req.app.get('io');
    
    if (notifications.length > 0) {
      const savedNotifications = await Notification.insertMany(notifications);
      if (io) {
        savedNotifications.forEach(n => {
          io.to(`user:${n.recipient}`).emit('notification_received', n);
        });
      }
    }
    
    const populatedReminder = await Reminder.findById(reminder._id)
      .populate('createdBy', 'name email avatar')
      .populate('participants.userId', 'name');
      
    const formatted = populatedReminder.toJSON();
    formatted.creatorName = req.user.name;
    formatted.createdBy = req.user.id;
    formatted.participants = formatted.participants.map(p => ({
      userId: p.userId._id,
      status: p.status,
      name: p.userId.name
    }));

    if (io) {
      participants.forEach(p => {
        io.to(`user:${p.userId}`).emit('new_event_created', formatted);
      });
    }

    res.status(201).json({ success: true, data: formatted });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// Participant accept shared reminder
const acceptSharedReminder = async (req, res) => {
  try {
    const reminder = await Reminder.findOne({ _id: req.params.id, isShared: true, 'participants.userId': req.user.id });

    if (!reminder) {
      return res.status(404).json({ success: false, message: 'Reminder not found' });
    }

    const participant = reminder.participants.find(p => p.userId.toString() === req.user.id);
    participant.status = 'accepted';
    await reminder.save();

    const populatedReminder = await Reminder.findById(reminder._id)
      .populate('createdBy', 'name email avatar')
      .populate('participants.userId', 'name');
      
    const formatted = populatedReminder.toJSON();
    formatted.creatorName = populatedReminder.createdBy.name;
    formatted.createdBy = populatedReminder.createdBy._id;
    formatted.participants = formatted.participants.map(p => ({
      userId: p.userId._id,
      status: p.status,
      name: p.userId.name
    }));

    const io = req.app.get('io');
    if (io) {
      io.to(`user:${populatedReminder.createdBy._id}`).emit('event_status_updated', formatted);
      formatted.participants.forEach(p => {
        if (p.userId.toString() !== req.user.id) {
          io.to(`user:${p.userId}`).emit('event_status_updated', formatted);
        }
      });
    }

    res.json({ success: true, data: formatted });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// Participant decline shared reminder
const declineSharedReminder = async (req, res) => {
  try {
    const reminder = await Reminder.findOne({ _id: req.params.id, isShared: true, 'participants.userId': req.user.id });

    if (!reminder) {
      return res.status(404).json({ success: false, message: 'Reminder not found' });
    }

    const participant = reminder.participants.find(p => p.userId.toString() === req.user.id);
    participant.status = 'declined';
    await reminder.save();

    const populatedReminder = await Reminder.findById(reminder._id)
      .populate('createdBy', 'name email avatar')
      .populate('participants.userId', 'name');
      
    const formatted = populatedReminder.toJSON();
    formatted.creatorName = populatedReminder.createdBy.name;
    formatted.createdBy = populatedReminder.createdBy._id;
    formatted.participants = formatted.participants.map(p => ({
      userId: p.userId._id,
      status: p.status,
      name: p.userId.name
    }));

    const io = req.app.get('io');
    if (io) {
      io.to(`user:${populatedReminder.createdBy._id}`).emit('event_status_updated', formatted);
      formatted.participants.forEach(p => {
        if (p.userId.toString() !== req.user.id) {
          io.to(`user:${p.userId}`).emit('event_status_updated', formatted);
        }
      });
    }

    res.json({ success: true, data: formatted });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// Participant mark as complete for themselves
const completeSharedParticipant = async (req, res) => {
  try {
    const reminder = await Reminder.findOne({ _id: req.params.id, isShared: true, 'participants.userId': req.user.id });

    if (!reminder) {
      return res.status(404).json({ success: false, message: 'Reminder not found' });
    }

    const participant = reminder.participants.find(p => p.userId.toString() === req.user.id);
    participant.status = 'completed';
    await reminder.save();

    const populatedReminder = await Reminder.findById(reminder._id)
      .populate('createdBy', 'name email avatar')
      .populate('participants.userId', 'name');
      
    const formatted = populatedReminder.toJSON();
    formatted.creatorName = populatedReminder.createdBy.name;
    formatted.createdBy = populatedReminder.createdBy._id;
    formatted.participants = formatted.participants.map(p => ({
      userId: p.userId._id,
      status: p.status,
      name: p.userId.name
    }));

    const io = req.app.get('io');
    if (io) {
      io.to(`user:${populatedReminder.createdBy._id}`).emit('event_status_updated', formatted);
      formatted.participants.forEach(p => {
        if (p.userId.toString() !== req.user.id) {
          io.to(`user:${p.userId}`).emit('event_status_updated', formatted);
        }
      });
    }

    res.json({ success: true, data: formatted });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// Get single reminder details
const getReminderById = async (req, res) => {
  try {
    const reminder = await Reminder.findById(req.params.id)
      .populate('createdBy', 'name')
      .populate('participants.userId', 'name');

    if (!reminder) {
      return res.status(404).json({ success: false, message: 'Reminder not found' });
    }

    // Check auth
    if (reminder.createdBy._id.toString() !== req.user.id) {
      // If shared, user must be a participant
      if (reminder.isShared) {
        const isParticipant = reminder.participants.some(p => p.userId._id.toString() === req.user.id);
        if (!isParticipant) {
          return res.status(401).json({ success: false, message: 'Not authorized' });
        }
      } else {
        return res.status(401).json({ success: false, message: 'Not authorized' });
      }
    }
    
    const formatted = reminder.toJSON();
    formatted.creatorName = reminder.createdBy.name;
    formatted.createdBy = reminder.createdBy._id;
    
    if (formatted.isShared) {
      formatted.participants = formatted.participants.map(p => ({
        userId: p.userId._id,
        status: p.status,
        name: p.userId.name
      }));
    }

    res.json({ success: true, data: formatted });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};


module.exports = {
  getReminders,
  createReminder,
  updateReminder,
  deleteReminder,
  completeReminder,
  getSharedWithMe,
  getSharedByMe,
  createSharedReminder,
  acceptSharedReminder,
  declineSharedReminder,
  completeSharedParticipant,
  getReminderById,
};
