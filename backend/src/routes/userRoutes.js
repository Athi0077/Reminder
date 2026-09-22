const express = require('express');
const router = express.Router();
const { getMe, updateProfile, updateAvatar, getNotificationSettings, updateNotificationSettings } = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');

router.get('/me', protect, getMe);
router.patch('/me', protect, updateProfile);
router.patch('/me/avatar', protect, updateAvatar);
router.get('/me/notification-settings', protect, getNotificationSettings);
router.patch('/me/notification-settings', protect, updateNotificationSettings);

module.exports = router;
