const mongoose = require('mongoose');

const participantSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'declined', 'completed'],
    default: 'pending',
  }
}, { _id: false });

const reminderSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
  },
  dateTime: {
    type: Date,
    required: true,
  },
  alertBefore: {
    type: String,
    default: 'tenMinutesBefore',
  },
  repeat: {
    type: String,
    default: 'doesNotRepeat',
  },
  category: {
    type: String,
    default: 'personal',
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  status: {
    type: String,
    enum: ['upcoming', 'completed', 'overdue'],
    default: 'upcoming',
  },
  isShared: {
    type: Boolean,
    default: false,
  },
  participants: [participantSchema],
}, {
  timestamps: true,
});

reminderSchema.methods.toJSON = function() {
  const obj = this.toObject();
  obj.id = obj._id;
  delete obj._id;
  delete obj.__v;
  return obj;
};

const Reminder = mongoose.model('Reminder', reminderSchema);
module.exports = Reminder;
