# MahaMaintain CRM Admin Website - Setup Guide

## Prerequisites

- Node.js 18+ and npm
- Firebase project account
- Git

## Installation Steps

### 1. Install Dependencies

```bash
npm install
```

### 2. Firebase Setup

#### Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a new project" or select existing one
3. Enable the following services:
   - **Authentication** → Sign-in methods: Email/Password
   - **Firestore Database** → Create in production mode
   - **Cloud Storage** → Create default bucket
   - **Web** app creation to get config

#### Get Firebase Credentials

1. In Firebase Console, go to Project Settings → General
2. Look for the Web SDK config section
3. Copy the config values

### 3. Environment Configuration

1. Copy `.env.example` to `.env.local`:
```bash
cp .env.example .env.local
```

2. Fill in your Firebase credentials in `.env.local`:
```
NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id
```

### 4. Firestore Security Rules

1. Go to Firestore Database → Rules
2. Replace with rules from Flutter app: `/firestore.rules`
3. Deploy the rules

### 5. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Demo Account

You can create accounts during registration, or use test credentials once set up:
- Email: admin@maha.com
- Password: admin123

## Project Structure

```
app/
├── auth/                    # Authentication pages (login, register, etc.)
├── dashboard/              # Main dashboard with KPIs and charts
├── leads/                  # Lead management (list, Kanban, detail, forms)
├── customers/              # Customer management (placeholder)
├── societies/              # Society management (placeholder)
├── service-requests/       # Service requests (placeholder)
└── admin/users/           # User management (placeholder)

components/
├── Layout.tsx             # Main app layout wrapper
├── Sidebar.tsx            # Navigation sidebar
├── Header.tsx             # Top header
├── Button.tsx             # Button component
├── Input.tsx              # Input component
├── Card.tsx               # Card component
├── Table.tsx              # Data table
├── Badge.tsx              # Badge component
├── Modal.tsx              # Modal dialog
├── RoleGate.tsx           # Permission-based access
└── leads/                 # Lead-specific components
    ├── LeadForm.tsx       # Create/edit lead form
    ├── LeadKanban.tsx     # Kanban view

lib/
├── firebase/
│   ├── config.ts          # Firebase initialization
│   ├── auth.ts            # Auth functions
│   ├── leads.ts           # Lead CRUD operations
│   ├── followups.ts       # Follow-up management
│   └── activities.ts      # Activity logging
└── permissions/
    └── permission-service.ts

hooks/
├── useAuth.ts             # Auth hook
├── usePermission.ts       # Permission check hook
├── useLeads.ts            # Leads data hook

stores/
├── auth-store.ts          # Zustand auth store
├── lead-store.ts          # Zustand leads store
└── app-store.ts           # Global UI state

types/
├── user.ts                # User types
├── lead.ts                # Lead types
├── common.ts              # Enums and common types
├── followup.ts            # Follow-up types
└── activity.ts            # Activity types
```

## Key Features

### ✅ Implemented
- Email/Password authentication
- Role-based access control (6 roles)
- Lead management (Create, Read, Update, Delete)
- Kanban board view with drag-and-drop
- Lead search and filtering
- Activity timeline
- Responsive dashboard with KPIs
- Firebase real-time data sync

### 🚧 In Progress
- Follow-up scheduling
- File attachments/uploads
- Notifications

### 📋 Planned
- Customer management
- Society management
- Service request tracking
- User role management
- Advanced analytics

## Technology Stack

- **Frontend**: Next.js 16, React 19, TypeScript
- **UI**: Tailwind CSS v4, Lucide Icons
- **State**: Zustand
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Charts**: Recharts

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

## Troubleshooting

### Firebase Connection Issues
- Verify `.env.local` file has correct credentials
- Check Firebase console for enabled services
- Ensure security rules are deployed

### Build Errors
- Clear `.next` folder: `rm -rf .next`
- Reinstall dependencies: `rm -rf node_modules && npm install`
- Check TypeScript errors: `npm run lint`

### Authentication Issues
- Clear browser localStorage: DevTools → Application → Local Storage → Clear All
- Check browser console for specific error messages
- Verify Firebase Authentication is enabled

## Deployment

### Vercel (Recommended)
```bash
npm install -g vercel
vercel
```

### Docker
```bash
docker build -t maha-admin .
docker run -p 3000:3000 maha-admin
```

## Contributing

1. Create a feature branch: `git checkout -b feature/feature-name`
2. Commit changes: `git commit -am 'Add feature'`
3. Push to branch: `git push origin feature/feature-name`
4. Submit pull request

## Support

For issues and questions, please contact the development team or create an issue in the repository.

## License

All rights reserved - MahaMaintain 2024
