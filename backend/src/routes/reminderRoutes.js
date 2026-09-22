const express = require('express');
const router = express.Router();
const { 
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
  getReminderById
} = require('../controllers/reminderController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

// Personal Routes
router.get('/', getReminders);
router.post('/', createReminder);

// Shared specific routes (MUST be before /:id)
router.post('/shared', createSharedReminder);
router.get('/shared/with-me', getSharedWithMe);
router.get('/shared/by-me', getSharedByMe);
router.patch('/shared/:id/accept', acceptSharedReminder);
router.patch('/shared/:id/decline', declineSharedReminder);
router.patch('/shared/:id/complete', completeSharedParticipant); // Participant completes

// General by ID
router.get('/:id', getReminderById);
router.put('/:id', updateReminder);
router.delete('/:id', deleteReminder);
router.patch('/:id/complete', completeReminder); // Creator completes personal

module.exports = router;
