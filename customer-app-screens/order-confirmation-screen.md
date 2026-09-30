# Order Confirmation Screen - Customer App

## UI Layout

```
╔════════════════════════════════════╗
║  ORDER CONFIRMED ✅               ║
║                                   ║
║  📦 Order ID: ORD1790794062902    ║
║  ₹2,500                           ║
╠════════════════════════════════════╣
║                                   ║
║  🔐 SERVICE COMPLETION OTP        ║
║                                   ║
║  ┌────────────────────────────┐   ║
║  │    123456                  │   ║
║  └────────────────────────────┘   ║
║                                   ║
║  [Copy OTP] [Share]              ║
║                                   ║
║  ⓘ Share this OTP with the      ║
║    service provider to verify     ║
║    service completion.            ║
║                                   ║
╠════════════════════════════════════╣
║  ORDER DETAILS                    ║
║                                   ║
║  Service: Hair Cut & Styling      ║
║  Location: Sector 12, Delhi       ║
║  Scheduled: Today, 3:00 PM        ║
║  Status: Pending Assignment       ║
║                                   ║
╠════════════════════════════════════╣
║  WHAT HAPPENS NEXT?               ║
║                                   ║
║  1️⃣ Vendor will be assigned       ║
║     within 30 minutes             ║
║                                   ║
║  2️⃣ You'll receive notification   ║
║     when vendor arrives           ║
║                                   ║
║  3️⃣ Service provider will ask     ║
║     for the OTP above             ║
║                                   ║
║  4️⃣ After service, check photos  ║
║     and rate the service          ║
║                                   ║
╠════════════════════════════════════╣
║  [Back to Home] [Track Order]    ║
╚════════════════════════════════════╝
```

## Key Features

### 1. OTP Display
- **Prominent**: Large, easy to read
- **Copyable**: One-tap copy to clipboard
- **Shareable**: Share via WhatsApp, SMS, etc.
- **Save**: Auto-save to My Bookings

### 2. Order Details
- Order ID
- Amount
- Service name
- Location/Address
- Scheduled time
- Current status

### 3. Information Box
- Explain OTP purpose
- Instructions for sharing
- What to expect next

### 4. Buttons
- **Track Order**: Real-time vendor location
- **Back to Home**: Continue shopping
- **My Bookings**: View order in bookings list

## API Response Structure

```json
{
  "success": true,
  "message": "Order created successfully",
  "order_id": "ORD1790794062902",
  "amount": 2500,
  "completion_otp": "123456"
}
```

## Customer My Bookings Display

After confirmation, OTP also visible in My Bookings:

```
ORDER: ORD1790794062902
Status: Pending Assignment ⏳

🔐 Completion OTP: 123456

Service: Hair Cut & Styling
📍 Sector 12, Delhi 110012
₹2,500

📸 Before Photo: [waiting]
📸 After Photo: [waiting]

⭐ Rating: [not rated yet]
```

## Workflow

```
Customer Places Order
         ↓
API Returns OTP: 123456
         ↓
Show Confirmation Screen
         ↓
Customer Sees/Copies OTP
         ↓
Customer Shares with Vendor
         ↓
Vendor Accepts Job
         ↓
Vendor Performs Service
         ↓
Vendor Asks for OTP
         ↓
Customer Provides OTP
         ↓
Vendor Enters OTP
         ↓
Service Verified ✓
         ↓
Customer Sees Photos
         ↓
Customer Rates (1-5 ⭐)
         ↓
Rating Saved to DB
```

## Security Points

1. OTP is 6-digit random (strong)
2. OTP saved in database
3. OTP verified before completion
4. Cannot be brute-forced easily
5. Customer controls when to share

## Mobile Screen Responsiveness

- Fits on 375px width (iPhone SE)
- Large touch targets for Copy/Share buttons
- Readable text at all sizes
- Scrollable for longer content
