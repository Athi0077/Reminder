const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
  },
  password: {
    type: String,
    required: true,
  },
  avatar: {
    type: String,
    default: null,
  },
  notificationSettings: {
    enabled: { type: Boolean, default: true },
    sound: { type: Boolean, default: true },
    vibration: { type: Boolean, default: true },
    defaultAlertMinutes: { type: Number, default: 10 }
  }
}, {
  timestamps: true,
});

userSchema.pre('save', async function() {
  if (!this.isModified('password')) return;
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

userSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

// Override toJSON to hide password
userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.password;
  // Convert _id to id
  obj.id = obj._id;
  delete obj._id;
  delete obj.__v;
  return obj;
};

const User = mongoose.model('User', userSchema);
module.exports = User;
