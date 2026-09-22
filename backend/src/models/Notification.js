const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  recipient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false,
  },
  type: {
    type: String,
    enum: ['friend_request', 'friend_request_accepted', 'reminder_shared', 'reminder_updated', 'reminder_completed', 'reminder_alert'],
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  relatedId: {
    type: mongoose.Schema.Types.ObjectId,
    required: false,
  },
  read: {
    type: Boolean,
    default: false,
  },
}, {
  timestamps: true,
});

notificationSchema.methods.toJSON = function() {
  const obj = this.toObject();
  obj.id = obj._id;
  delete obj._id;
  delete obj.__v;
  return obj;
};

const Notification = mongoose.model('Notification', notificationSchema);
module.exports = Notification;
