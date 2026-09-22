const express = require('express');
const router = express.Router();
const { registerUser, loginUser, getMe, changePassword, deleteAccount } = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

router.post('/register', registerUser);
router.post('/login', loginUser);
router.patch('/change-password', protect, changePassword);
router.delete('/account', protect, deleteAccount);

module.exports = router;
