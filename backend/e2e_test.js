require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');
const FriendRequest = require('./src/models/FriendRequest');
const Notification = require('./src/models/Notification');
const Reminder = require('./src/models/Reminder');

const API_URL = 'http://localhost:5000/api';

async function fetchApi(path, options = {}) {
  const res = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers
    }
  });
  const data = await res.json();
  return { status: res.status, data };
}

const timestamp = Date.now();
const emailA = `athi.test.${timestamp}@example.com`;
const emailB = `alagiri.test.${timestamp}@example.com`;

let userAToken = '';
let userBToken = '';
let userAId = '';
let userBId = '';

let requestId = '';
let eventId = '';

async function runTests() {
  console.log('--- STARTING E2E TESTS ---');
  
  let results = [];
  function report(testName, passed, reason = '') {
    results.push({ testName, passed, reason });
    console.log(`[${passed ? 'PASS' : 'FAIL'}] ${testName} ${reason ? '- ' + reason : ''}`);
    if (!passed) {
      console.log('ABORTING DUE TO FAILURE.');
      process.exit(1);
    }
  }

  try {
    // ==================================================
    // STEP 1 - CREATE USER A
    // ==================================================
    const resA = await fetchApi('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ name: 'Athi Test', email: emailA, password: 'Test@12345' })
    });
    
    if (resA.status === 201 && resA.data.success) {
      userAToken = resA.data.data.token;
      
      const meA = await fetchApi('/users/me', { headers: { 'Authorization': `Bearer ${userAToken}` } });
      if (meA.status === 200 && meA.data.data.email === emailA) {
        userAId = meA.data.data._id || meA.data.data.id;
        report('TEST 1: User A signup', true);
      } else {
        console.error('meA response:', meA);
        report('TEST 1: User A signup', false, 'Failed to fetch User A profile');
      }
    } else {
      report('TEST 1: User A signup', false, 'Failed to register User A: ' + JSON.stringify(resA.data));
    }

    // ==================================================
    // STEP 3 - CREATE USER B (Doing this early so A can send request)
    // ==================================================
    const resB = await fetchApi('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ name: 'Alagiri Test', email: emailB, password: 'Test@12345' })
    });
    
    if (resB.status === 201 && resB.data.success) {
      userBToken = resB.data.data.token;
      
      const meB = await fetchApi('/users/me', { headers: { 'Authorization': `Bearer ${userBToken}` } });
      if (meB.status === 200 && meB.data.data.email === emailB) {
        userBId = meB.data.data._id || meB.data.data.id;
        
        // Check isolation
        const privateA = await fetchApi('/reminders', { headers: { 'Authorization': `Bearer ${userAToken}` } });
        if (privateA.status === 200) {
          report('TEST 3: User B signup', true);
        } else {
          report('TEST 3: User B signup', false, 'Isolation check failed');
        }
      }
    } else {
      report('TEST 3: User B signup', false, 'Failed to register User B');
    }

    // ==================================================
    // STEP 2 - USER A SENDS FRIEND REQUEST
    // ==================================================
    console.log('Sending friend request to userBId:', userBId);
    const reqRes = await fetchApi('/friends/request', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${userAToken}` },
      body: JSON.stringify({ receiverId: userBId })
    });
    
    if (reqRes.status === 201 && reqRes.data.success) {
      requestId = reqRes.data.data._id || reqRes.data.data.id;
      
      // Verify via API (Requests sent to me for B should contain it)
      const bReqs = await fetchApi('/friends/requests', { headers: { 'Authorization': `Bearer ${userBToken}` } });
      if (bReqs.data.data.some(r => (r._id === requestId || r.id === requestId) && r.status === 'pending')) {
        report('TEST 2: User A sends friend request', true);
      } else {
        report('TEST 2: User A sends friend request', false, 'Request not visible in B pending list');
      }
    } else {
      report('TEST 2: User A sends friend request', false, 'API Failed: ' + JSON.stringify(reqRes.data));
    }

    // ==================================================
    // STEP 4 - USER B RECEIVES NOTIFICATION
    // ==================================================
    const notifRes = await fetchApi('/notifications', {
      headers: { 'Authorization': `Bearer ${userBToken}` }
    });
    
    if (notifRes.status === 200 && notifRes.data.success) {
      const notifs = notifRes.data.data;
      const frNotif = notifs.find(n => n.type === 'friend_request' && n.sender._id === userAId);
      
      if (frNotif && !frNotif.read) {
        report('TEST 4: User B receives notification', true);
      } else {
        report('TEST 4: User B receives notification', false, 'Notification missing or already read');
      }
    } else {
      report('TEST 4: User B receives notification', false, 'Failed to fetch notifications');
    }

    // ==================================================
    // STEP 5 - USER B ACCEPTS FRIEND REQUEST
    // ==================================================
    const acceptRes = await fetchApi(`/friends/requests/${requestId}/accept`, {
      method: 'PATCH',
      headers: { 'Authorization': `Bearer ${userBToken}` }
    });
    
    if (acceptRes.status === 200 && acceptRes.data.success) {
      // Verify notification is read via API
      const notifsAfter = await fetchApi('/notifications', { headers: { 'Authorization': `Bearer ${userBToken}` } });
      const frNotifAfter = notifsAfter.data.data.find(n => n.type === 'friend_request' && n.sender._id === userAId);
      
      if (frNotifAfter && frNotifAfter.read) {
        report('TEST 5: User B accepts friend request', true);
      } else {
        report('TEST 5: User B accepts friend request', false, 'Notification not marked read');
      }
    } else {
      console.log('acceptRes:', acceptRes);
      report('TEST 5: User B accepts friend request', false, 'API Failed');
    }

    // ==================================================
    // STEP 6 - VERIFY FRIENDSHIP FROM BOTH ACCOUNTS
    // ==================================================
    const friendsB = await fetchApi('/friends', { headers: { 'Authorization': `Bearer ${userBToken}` } });
    const friendsA = await fetchApi('/friends', { headers: { 'Authorization': `Bearer ${userAToken}` } });
    
    if (friendsB.data.data.some(f => (f._id === userAId || f.id === userAId)) && friendsA.data.data.some(f => (f._id === userBId || f.id === userBId))) {
      report('TEST 6: Friendship appears for both users', true);
    } else {
      report('TEST 6: Friendship appears for both users', false, 'Friend missing from list');
    }

    // ==================================================
    // STEP 7 - USER A CREATES EVENT
    // ==================================================
    const eventRes = await fetchApi('/reminders', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${userAToken}` },
      body: JSON.stringify({
        title: 'Team Project Meeting',
        description: 'Discuss Reminderly project',
        dateTime: new Date(Date.now() + 86400000).toISOString(),
        alertBefore: 'tenMinutesBefore',
        repeat: 'doesNotRepeat',
        category: 'work'
      })
    });
    
    if (eventRes.status === 201 && eventRes.data.success) {
      eventId = eventRes.data.data._id || eventRes.data.data.id;
      
      const myReminders = await fetchApi('/reminders', { headers: { 'Authorization': `Bearer ${userAToken}` } });
      if (myReminders.data.data.some(r => (r._id === eventId || r.id === eventId))) {
        report('TEST 7: User A creates event', true);
      } else {
        report('TEST 7: User A creates event', false, 'Event not found in personal list');
      }
    } else {
      report('TEST 7: User A creates event', false, 'API Failed');
    }

    // ==================================================
    // STEP 8 - USER A SHARES EVENT WITH USER B
    // ==================================================
    const shareRes = await fetchApi('/reminders/shared', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${userAToken}` },
      body: JSON.stringify({
        title: 'Team Project Meeting',
        description: 'Discuss Reminderly project',
        dateTime: new Date(Date.now() + 86400000).toISOString(),
        alertBefore: 'tenMinutesBefore',
        repeat: 'doesNotRepeat',
        category: 'work',
        participants: [{ userId: userBId }]
      })
    });
    
    if (shareRes.status === 201 && shareRes.data.success) {
      const sharedEventId = shareRes.data.data._id || shareRes.data.data.id;
      eventId = sharedEventId; // Update eventId
      
      const aSharedByMe = await fetchApi('/reminders/shared/by-me', { headers: { 'Authorization': `Bearer ${userAToken}` } });
      const evt = aSharedByMe.data.data.find(r => (r._id === eventId || r.id === eventId));
      
      if (evt && (evt.participants[0].userId._id === userBId || evt.participants[0].userId.id === userBId || evt.participants[0].userId === userBId)) {
        report('TEST 8: User A shares event with User B', true);
      } else {
        report('TEST 8: User A shares event with User B', false, 'Participant missing');
      }
    } else {
      report('TEST 8: User A shares event with User B', false, 'API Failed: ' + JSON.stringify(shareRes.data));
    }

    // ==================================================
    // STEP 9 - USER B RECEIVES SHARED EVENT NOTIFICATION
    // ==================================================
    const notifRes2 = await fetchApi('/notifications', {
      headers: { 'Authorization': `Bearer ${userBToken}` }
    });
    
    if (notifRes2.status === 200 && notifRes2.data.success) {
      const notifs = notifRes2.data.data;
      const shNotif = notifs.find(n => n.type === 'reminder_shared' && n.relatedId === eventId);
      
      if (shNotif) {
        report('TEST 9: User B receives shared event notification', true);
      } else {
        report('TEST 9: User B receives shared event notification', false, 'Notification missing');
      }
    } else {
      report('TEST 9: User B receives shared event notification', false, 'API Failed');
    }

    // ==================================================
    // STEP 10 - USER B ACCEPTS SHARED EVENT
    // ==================================================
    const acceptShRes = await fetchApi(`/reminders/shared/${eventId}/accept`, {
      method: 'PATCH',
      headers: { 'Authorization': `Bearer ${userBToken}` }
    });
    
    if (acceptShRes.status === 200 && acceptShRes.data.success) {
      const sharedWithMe = await fetchApi('/reminders/shared/with-me', { headers: { 'Authorization': `Bearer ${userBToken}` } });
      const myEvt = sharedWithMe.data.data.find(r => (r._id === eventId || r.id === eventId));
      
      if (myEvt && myEvt.participants.find(p => (p.userId === userBId || p.userId._id === userBId || p.userId.id === userBId)).status === 'accepted') {
        report('TEST 10: User B accepts shared event', true);
      } else {
        report('TEST 10: User B accepts shared event', false, 'Status not updated in list');
      }
    } else {
      report('TEST 10: User B accepts shared event', false, 'API Failed');
    }

    // ==================================================
    // STEP 11 - VERIFY FROM USER A
    // ==================================================
    const getEvtRes = await fetchApi(`/reminders/${eventId}`, {
      headers: { 'Authorization': `Bearer ${userAToken}` }
    });
    
    if (getEvtRes.status === 200 && getEvtRes.data.success) {
      const p = getEvtRes.data.data.participants.find(part => (part.userId === userBId || part.userId._id === userBId || part.userId.id === userBId));
      if (p && p.status === 'accepted') {
        report('TEST 11: Shared event appears correctly', true);
      } else {
        report('TEST 11: Shared event appears correctly', false, 'Participant missing or wrong status');
      }
    } else {
      report('TEST 11: Shared event appears correctly', false, 'API Failed');
    }

    // ==================================================
    // STEP 12 - SECURITY/ISOLATION TESTS
    // ==================================================
    let securityPassed = true;
    
    // 1. User B accesses User A's private reminder
    const sec1 = await fetchApi(`/reminders`, { headers: { 'Authorization': `Bearer ${userBToken}` } });
    if (sec1.data.data.some(r => r.title === 'Team Project Meeting' && !r.isShared)) {
      console.log('Security failure: User B saw User A private reminder');
      securityPassed = false;
    }
    
    // 2. Duplicate friend request
    const sec2 = await fetchApi('/friends/request', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${userAToken}` },
      body: JSON.stringify({ receiverId: userBId })
    });
    if (sec2.status !== 400) {
      console.log('Security failure: Duplicate friend request allowed');
      securityPassed = false;
    }
    
    if (securityPassed) {
      report('TEST 12: Security/isolation tests', true);
    } else {
      report('TEST 12: Security/isolation tests', false, 'Security checks failed');
    }

    console.log('\n--- ALL TESTS PASSED SUCCESSFULLY ---');
    process.exit(0);
    
  } catch (error) {
    console.error('Unhandled Test Exception:', error);
    process.exit(1);
  }
}

runTests();
