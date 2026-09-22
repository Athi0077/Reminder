const express = require('express');
const router = express.Router();
const { 
  searchUsers, 
  sendFriendRequest, 
  getFriendRequests, 
  acceptRequest, 
  rejectRequest, 
  getFriends, 
  removeFriend 
} = require('../controllers/friendController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/', getFriends);
router.get('/search', searchUsers);
router.post('/request', sendFriendRequest);
router.get('/requests', getFriendRequests);
router.patch('/requests/:id/accept', acceptRequest);
router.patch('/requests/:id/reject', rejectRequest);
router.delete('/:id', removeFriend);

module.exports = router;
