# Dashboard Architecture - Role-Based Tab Content

## Overview
All users see the same consistent dashboard structure. The **user role determines what content appears in the Society tab**.

## Architecture Flow

```
DashboardScreen (receives userRole)
    ↓
IndividualDashboardScreen (receives userRole)
    ├── Tab 0: SearchScreen (Home)
    ├── Tab 1: SearchListScreen (Search)
    ├── Tab 2: AiChatScreen (AI Chat)
    ├── Tab 3: CONDITIONAL based on userRole
    │   ├─→ IF society member: SocietyTabScreen (NEW orange dashboard)
    │   └─→ IF individual: SocietyScreen (register your society)
    ├── Tab 4: BookingsScreen (Bookings)
    └── Tab 5: ProfileScreen (Profile)
```

## User Experience

### Individual User (individual@example.com)
```
Bottom Nav: Home | Search | AI Chat | Society | Bookings | Profile
            ✓      ✓        ✓       ✓         ✓          ✓

Society Tab → Shows "Register Your Society" page
Other Tabs  → Work as normal
```

### Society Member (society@gmail.com)
```
Bottom Nav: Home | Search | AI Chat | Society | Bookings | Profile
            ✓      ✓        ✓       ✓         ✓          ✓

Society Tab → Shows NEW Society Dashboard:
              • Orange header (orange gradient)
              • Dashboard, Photos, Notices tabs
              • Visitor Gate, Parking, Tenant Management
              • Complaints & Tickets section
              • Society Notices with categories
Other Tabs  → Work as normal
```

## Key Files

### 1. **DashboardScreen** (`lib/screens/dashboard_screen.dart`)
- Entry point after login
- Always shows `IndividualDashboardScreen` for all users
- Passes `userRole` parameter

### 2. **IndividualDashboardScreen** (`lib/screens/individual_dashboard_screen.dart`)
- Main dashboard structure (6 tabs)
- Receives `userRole` parameter (default: 'individual')
- Conditionally shows different Society tab based on role
- Manages bottom navigation for all users

### 3. **SocietyTabScreen** (`lib/screens/society_tab_screen.dart`)
- NEW: Society Dashboard with orange theme
- Shown in Tab 3 when user is a society member
- Has its own Dashboard, Photos, Notices sub-tabs
- Completely independent state management

### 4. **SocietyScreen** (`lib/screens/society_screen.dart`)
- Existing "Register Your Society" page
- Shown in Tab 3 when user is an individual
- Unchanged from before

## Design Benefits

✅ **Consistent Experience** - All users see the same 6-tab structure  
✅ **Role-Based Content** - Only the Society tab changes based on role  
✅ **Independent State** - Each dashboard/tab has its own state  
✅ **Single Navigation** - Same bottom nav for everyone  
✅ **No State Bleeding** - Changes in one section don't affect others  
✅ **Easy to Extend** - Add more role-based tabs easily  

## How It Works

1. User logs in with email (e.g., `society@gmail.com`)
2. Role is detected in `AppRouter` based on email
3. `DashboardScreen` receives the role
4. `IndividualDashboardScreen` receives the role
5. When user clicks Society tab (Tab 3):
   - If role is 'society' → shows `SocietyTabScreen` 
   - If role is 'individual' → shows `SocietyScreen`
6. All other tabs remain unchanged

## Testing the Feature

### For Individual Users:
1. Login with any email except: `society@gmail.com`, `admin@society.com`, `societyadmin@demo.com`
2. Click "Society" button in bottom nav
3. Should see "Register Your Society" page

### For Society Members:
1. Click "Society Demo" button on login (uses `society@gmail.com`)
2. Complete OTP verification
3. Click "Society" button in bottom nav
4. Should see NEW orange-themed Society Dashboard with:
   - Dashboard, Photos, Notices tabs
   - Menu items (Visitor Gate, Parking, etc.)
   - Complaints section
   - Notices section

## No Breaking Changes

✅ Individual Dashboard tabs work the same  
✅ All existing functionality preserved  
✅ Only the Society tab content changes based on role  
✅ Navigation remains consistent  
✅ Bottom nav is the same for everyone  
