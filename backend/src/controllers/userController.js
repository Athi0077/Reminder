const User = require('../models/User');
const Reminder = require('../models/Reminder');
const FriendRequest = require('../models/FriendRequest');

const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Get statistics
    const totalReminders = await Reminder.countDocuments({ createdBy: req.user.id });
    const completedReminders = await Reminder.countDocuments({ createdBy: req.user.id, status: 'completed' });
    const sharedReminders = await Reminder.countDocuments({ 
      'participants.userId': req.user.id,
      isShared: true
    });
    
    // Accepted friends
    const friendsCount = await FriendRequest.countDocuments({
      status: 'accepted',
      $or: [{ sender: req.user.id }, { receiver: req.user.id }]
    });

    res.json({
      success: true,
      data: {
        ...user.toJSON(),
        stats: {
          totalReminders,
          completedReminders,
          sharedReminders,
          friendsCount
        }
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { name, email } = req.body;
    
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (name) user.name = name;
    
    if (email && email !== user.email) {
      // Check if email already exists
      const emailExists = await User.findOne({ email });
      if (emailExists) {
        return res.status(400).json({ success: false, message: 'Email already in use' });
      }
      user.email = email;
    }

    await user.save();
    
    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

const updateAvatar = async (req, res) => {
  try {
    const { avatarUrl } = req.body;
    
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.avatar = avatarUrl || null;
    await user.save();
    
    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

const getNotificationSettings = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json({ success: true, data: user.notificationSettings });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

const updateNotificationSettings = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (req.body.enabled !== undefined) user.notificationSettings.enabled = req.body.enabled;
    if (req.body.sound !== undefined) user.notificationSettings.sound = req.body.sound;
    if (req.body.vibration !== undefined) user.notificationSettings.vibration = req.body.vibration;
    if (req.body.defaultAlertMinutes !== undefined) user.notificationSettings.defaultAlertMinutes = req.body.defaultAlertMinutes;

    await user.save();
    res.json({ success: true, data: user.notificationSettings });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

module.exports = {
  getMe,
  updateProfile,
  updateAvatar,
  getNotificationSettings,
  updateNotificationSettings
};
