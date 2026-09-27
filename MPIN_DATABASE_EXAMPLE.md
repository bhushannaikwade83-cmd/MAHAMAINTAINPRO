# M-PIN Database - What Gets Saved

## Database Table: `user_mpin`

### Real Example: User sets M-PIN "1234"

**When user enters M-PIN: `1234`**

```
Phone Number: +919876543210
M-PIN: 1234 (user enters this)
```

**What gets saved in database:**

```
id              | phone_number      | mpin_hash                                                    | created_at          | updated_at
1               | +919876543210     | $2y$10$X5k8L9mN2pQ1r3sT4uV5wE6fG7hI8jK9lM0nO1pQ2rS3tU4vW5xY | 2026-09-24 10:30:00 | 2026-09-24 10:30:00
```

---

## What Each Column Contains:

### 1. **id** 
- Auto-increment ID
- Value: `1, 2, 3...`
- Just for database reference

### 2. **phone_number** ⭐ (UNIQUE)
- User's actual phone number
- Value: `+919876543210`
- **Same number can't have 2 different M-PINs**

### 3. **mpin_hash** 🔒 (ENCRYPTED)
- **NOT** the plain M-PIN
- Plain text "1234" is converted to bcrypt hash
- Value: `$2y$10$X5k8L9mN2pQ1r3sT4uV5wE6fG7hI8jK9lM0nO1pQ2rS3tU4vW5xY`
- **Cannot be reversed** - super secure!
- Each M-PIN generates different hash

### 4. **created_at**
- When M-PIN was first set
- Value: `2026-09-24 10:30:00`

### 5. **updated_at**
- When M-PIN was last changed
- Value: `2026-09-24 10:30:00`

---

## Real-World Example Scenarios

### Scenario 1: User 1 Sets M-PIN
```
User enters phone: +919876543210
User creates M-PIN: 1234

Database saves:
┌────────────────────────────────────────────────────┐
│ id  │ phone_number   │ mpin_hash (bcrypt)  │ time  │
├────────────────────────────────────────────────────┤
│ 1   │ +919876543210  │ $2y$10$X5k8L9mN...  │ 10:30 │
└────────────────────────────────────────────────────┘
```

### Scenario 2: User 2 Sets M-PIN  
```
User enters phone: +918765432109
User creates M-PIN: 5678

Database now has:
┌────────────────────────────────────────────────────┐
│ id  │ phone_number   │ mpin_hash (bcrypt)  │ time  │
├────────────────────────────────────────────────────┤
│ 1   │ +919876543210  │ $2y$10$X5k8L9mN...  │ 10:30 │
│ 2   │ +918765432109  │ $2y$10$K7h9L2pQ...  │ 10:45 │
└────────────────────────────────────────────────────┘
```

### Scenario 3: User 1 Changes M-PIN (from 1234 → 9999)
```
User enters phone: +919876543210
User creates NEW M-PIN: 9999

Database updates:
┌────────────────────────────────────────────────────┐
│ id  │ phone_number   │ mpin_hash (bcrypt)  │ time  │
├────────────────────────────────────────────────────┤
│ 1   │ +919876543210  │ $2y$10$N9m5R4sT...  │ 11:00 │ ← UPDATED!
│ 2   │ +918765432109  │ $2y$10$K7h9L2pQ...  │ 10:45 │
└────────────────────────────────────────────────────┘
```

---

## How Verification Works

### User tries to login with M-PIN on Device 2:

**User enters:**
```
Phone: +919876543210
M-PIN: 1234
```

**App does:**
1. Sends to API: `verify-mpin.php`
2. API fetches from DB where phone = +919876543210
3. Gets stored hash: `$2y$10$X5k8L9mN...`
4. Uses `password_verify("1234", "$2y$10$X5k8L9mN...")` 
5. ✅ Returns TRUE → Login success!

**If user enters wrong M-PIN:**
```
User enters M-PIN: 9999 (wrong!)
password_verify("9999", "$2y$10$X5k8L9mN...") 
❌ Returns FALSE → Login failed!
```

---

## Security Questions

### Q1: Can admin see user's M-PIN?
❌ **NO** - Only bcrypt hash stored, not plain M-PIN

### Q2: If database is leaked, can hackers get M-PIN?
❌ **NO** - Bcrypt is one-way encryption, cannot be reversed

### Q3: Can same M-PIN be set by 2 users?
✅ **YES** - Different phones = different entries
```
Phone: +919876543210 → M-PIN hash: $2y$10$X5k8L9mN...
Phone: +918765432109 → M-PIN hash: $2y$10$X5k8L9mN... (same hash, different phone)
```

### Q4: What if user forgets M-PIN?
- User can reset: Login with OTP → Create new M-PIN
- Old M-PIN is replaced in database

---

## Important Notes

✅ **Saved in Database:**
- Phone number (plain text)
- Bcrypt-hashed M-PIN (encrypted)
- Timestamps

❌ **NOT Saved:**
- Plain text M-PIN
- User's name
- User's email
- Any personal info

---

## Useful SQL to View Data

**See all users and their M-PIN status (safe):**
```sql
SELECT id, phone_number, created_at FROM user_mpin;
```

**Check if specific user has M-PIN:**
```sql
SELECT EXISTS(SELECT 1 FROM user_mpin WHERE phone_number = '+919876543210') as has_mpin;
```

**Reset M-PIN for user (if they forgot):**
```sql
DELETE FROM user_mpin WHERE phone_number = '+919876543210';
-- User must login with OTP again and set new M-PIN
```

---

## Real-time Sync ✨

Currently: Database updates instantly when M-PIN is set.

Next: Can add real-time notifications if needed (Supabase real-time subscriptions).
