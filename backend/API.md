# Remindly API Documentation

## Base URL
`/api`

## Authentication (`/api/auth`)

### Register
- **Method:** POST `/auth/register`
- **Body:** `{ "name": "...", "email": "...", "password": "..." }`
- **Response:** `{ "success": true, "data": { "user": {}, "token": "..." } }`

### Login
- **Method:** POST `/auth/login`
- **Body:** `{ "email": "...", "password": "..." }`
- **Response:** `{ "success": true, "data": { "user": {}, "token": "..." } }`

### Change Password
- **Method:** PATCH `/auth/change-password`
- **Auth:** Bearer Token
- **Body:** `{ "currentPassword": "...", "newPassword": "..." }`
- **Response:** `{ "success": true, "message": "Password changed successfully" }`

### Delete Account
- **Method:** DELETE `/auth/account`
- **Auth:** Bearer Token
- **Response:** `{ "success": true, "message": "Account deleted successfully" }`

---

## Users (`/api/users`)

### Get Current User Profile
- **Method:** GET `/users/me`
- **Auth:** Bearer Token
- **Response:** 
```json
{
  "success": true, 
  "data": { 
    "name": "...", "email": "...", "avatar": "...", "id": "...",
    "stats": {
      "totalReminders": 10,
      "completedReminders": 5,
      "sharedReminders": 2,
      "friendsCount": 3
    }
  } 
}
```

### Update Profile
- **Method:** PATCH `/users/me`
- **Auth:** Bearer Token
- **Body:** `{ "name": "...", "email": "..." }`
- **Response:** `{ "success": true, "data": {} }`

### Update Avatar
- **Method:** PATCH `/users/me/avatar`
- **Auth:** Bearer Token
- **Body:** `{ "avatarUrl": "..." }`
- **Response:** `{ "success": true, "data": {} }`

---

## Friends (`/api/friends`)
*All friend endpoints require authentication (Bearer Token).*

### Search Users
- **Method:** GET `/friends/search?query=...`
- **Response:** `{ "success": true, "data": [...] }`

### Send Friend Request
- **Method:** POST `/friends/request`
- **Body:** `{ "receiverId": "..." }`

### Get Friend Requests
- **Method:** GET `/friends/requests`

### Accept Request
- **Method:** PATCH `/friends/requests/:id/accept`

### Reject Request
- **Method:** PATCH `/friends/requests/:id/reject`

### Get Friends
- **Method:** GET `/friends`

### Remove Friend
- **Method:** DELETE `/friends/:id`

---

## Reminders (`/api/reminders`)
*All reminder endpoints require authentication (Bearer Token).*

### Create Reminder
- **Method:** POST `/reminders`
- **Body:** `{ "title": "...", "dateTime": "...", "description": "...", "alertBefore": "...", "repeat": "...", "category": "..." }`

### Get All Reminders
- **Method:** GET `/reminders`

### Get Shared Reminders
- **Method:** GET `/reminders/shared`

### Get Reminder by ID
- **Method:** GET `/reminders/:id`

### Update Reminder
- **Method:** PUT `/reminders/:id`

### Delete Reminder
- **Method:** DELETE `/reminders/:id`

### Share Reminder
- **Method:** POST `/reminders/:id/share`
- **Body:** `{ "userId": "..." }`

### Respond to Share
- **Method:** PATCH `/reminders/:id/respond`
- **Body:** `{ "status": "accepted|declined" }`

### Mark Completed
- **Method:** PATCH `/reminders/:id/complete`
