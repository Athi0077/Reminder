const FriendRequest = require('../models/FriendRequest');
const User = require('../models/User');
const Notification = require('../models/Notification');

/**
 * @desc    Search users by name or email (excluding self)
 * @route   GET /api/friends/search
 * @access  Private
 */
const searchUsers = async (req, res) => {
  try {
    const { query } = req.query;
    if (!query) {
      return res.json({ success: true, data: [] });
    }
    
    // Search by name or email, excluding current user
    const users = await User.find({
      $and: [
        { _id: { $ne: req.user.id } },
        {
          $or: [
            { name: { $regex: query, $options: 'i' } },
            { email: { $regex: query, $options: 'i' } },
          ]
        }
      ]
    }).select('-password');
    
    res.json({ success: true, data: users });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

/**
 * @desc    Send a friend request to a user and emit real-time socket events
 * @route   POST /api/friends/request
 * @access  Private
 */
const sendFriendRequest = async (req, res) => {
  try {
    const { receiverId } = req.body;
    
    if (receiverId === req.user.id) {
      return res.status(400).json({ success: false, message: 'Cannot send request to yourself' });
    }
    
    let friendRequest = await FriendRequest.findOne({
      $or: [
        { sender: req.user.id, receiver: receiverId },
        { sender: receiverId, receiver: req.user.id }
      ]
    });
    
    if (friendRequest) {
      if (friendRequest.status === 'pending' || friendRequest.status === 'accepted') {
        return res.status(400).json({ success: false, message: 'Request already exists or you are already friends' });
      } else {
        // Reuse rejected request
        friendRequest.sender = req.user.id;
        friendRequest.receiver = receiverId;
        friendRequest.status = 'pending';
        await friendRequest.save();
      }
    } else {
      friendRequest = await FriendRequest.create({
        sender: req.user.id,
        receiver: receiverId,
      });
    }
    
    // Create notification
    const notification = await Notification.create({
      recipient: receiverId,
      sender: req.user.id,
      type: 'friend_request',
      title: 'New Friend Request',
      message: `${req.user.name} sent you a friend request`,
      relatedId: friendRequest._id,
    });
    
    // Populate sender info before emitting to socket
    const populatedRequest = await FriendRequest.findById(friendRequest._id)
      .populate('sender', 'name email avatar');

    // Emit socket event to the receiver
    const io = req.app.get('io');
    if (io) {
      io.to(`user:${receiverId}`).emit('friend_request_received', populatedRequest);
      io.to(`user:${receiverId}`).emit('notification_received', notification);
    }
    
    res.status(201).json({ success: true, data: friendRequest });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

/**
 * @desc    Get all pending friend requests for the current user
 * @route   GET /api/friends/requests
 * @access  Private
 */
const getFriendRequests = async (req, res) => {
  try {
    // Requests sent to me
    const requests = await FriendRequest.find({ receiver: req.user.id, status: 'pending' })
      .populate('sender', 'name email avatar')
      .sort('-createdAt');
      
    res.json({ success: true, data: requests });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

/**
 * @desc    Accept a friend request and notify the sender via socket
 * @route   PATCH /api/friends/requests/:id/accept
 * @access  Private
 */
const acceptRequest = async (req, res) => {
  try {
    const request = await FriendRequest.findOne({ _id: req.params.id, receiver: req.user.id });
    
    if (!request) {
      return res.status(404).json({ success: false, message: 'Request not found' });
    }
    
    request.status = 'accepted';
    await request.save();
    
    // Mark friend_request notification as read
    await Notification.updateMany(
      { recipient: req.user.id, relatedId: request._id, type: 'friend_request' },
      { $set: { read: true } }
    );
    
    // Create friend_request_accepted notification for the original sender
    const notification = await Notification.create({
      recipient: request.sender,
      sender: req.user.id,
      type: 'friend_request_accepted',
      title: 'Friend Request Accepted',
      message: `${req.user.name} accepted your friend request`,
      relatedId: request._id,
    });
    
    // Emit socket event to the original sender
    const io = req.app.get('io');
    if (io) {
      const senderIdStr = request.sender.toString();
      io.to(`user:${senderIdStr}`).emit('friend_request_accepted', {
        requestId: request._id,
        receiverId: req.user.id,
        receiverName: req.user.name,
        receiverAvatar: req.user.avatar,
        receiverEmail: req.user.email
      });
      io.to(`user:${senderIdStr}`).emit('notification_received', notification);
    }
    
    res.json({ success: true, data: request });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

/**
 * @desc    Reject a friend request
 * @route   PATCH /api/friends/requests/:id/reject
 * @access  Private
 */
const rejectRequest = async (req, res) => {
  try {
    const request = await FriendRequest.findOne({ _id: req.params.id, receiver: req.user.id });
    
    if (!request) {
      return res.status(404).json({ success: false, message: 'Request not found' });
    }
    
    request.status = 'rejected';
    await request.save();
    
    // Mark friend_request notification as read
    await Notification.updateMany(
      { recipient: req.user.id, relatedId: request._id, type: 'friend_request' },
      { $set: { read: true } }
    );
    
    res.json({ success: true, message: 'Request rejected' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

/**
 * @desc    Get all accepted friends for the current user
 * @route   GET /api/friends
 * @access  Private
 */
const getFriends = async (req, res) => {
  try {
    const friendships = await FriendRequest.find({
      $or: [
        { sender: req.user.id, status: 'accepted' },
        { receiver: req.user.id, status: 'accepted' }
      ]
    }).populate('sender', 'name email avatar').populate('receiver', 'name email avatar');
    
    const friends = friendships.map(f => {
      // If I am the sender, the friend is the receiver
      if (f.sender._id.toString() === req.user.id) {
        return f.receiver;
      }
      return f.sender;
    });
    
    res.json({ success: true, data: friends });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

/**
 * @desc    Remove a friend by deleting the accepted friend request
 * @route   DELETE /api/friends/:id
 * @access  Private
 */
const removeFriend = async (req, res) => {
  try {
    const friendId = req.params.id;
    await FriendRequest.findOneAndDelete({
      status: 'accepted',
      $or: [
        { sender: req.user.id, receiver: friendId },
        { sender: friendId, receiver: req.user.id }
      ]
    });
    
    res.json({ success: true, message: 'Friend removed' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

module.exports = {
  searchUsers,
  sendFriendRequest,
  getFriendRequests,
  acceptRequest,
  rejectRequest,
  getFriends,
  removeFriend
};
