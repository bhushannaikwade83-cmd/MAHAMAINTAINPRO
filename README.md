# MahaMaintain CRM - Admin Dashboard

Modern Next.js admin panel for managing MahaMaintain Pro society maintenance services.

## 🚀 Features

- **Dashboard**: KPI metrics, revenue charts, pipeline distribution, recent leads
- **Pipeline/Kanban**: Visual drag-and-drop lead management across stages
- **Leads Management**: Complete lead database with search, filtering, and actions
- **Authentication**: Secure admin login (email/password)
- **Analytics**: Revenue trends, win rates, stage distribution

## 🛠 Tech Stack

- **Frontend**: Next.js 16+, React 19, TypeScript
- **Styling**: Tailwind CSS
- **Charts**: Recharts
- **Icons**: Lucide React

## 📦 Installation

```bash
cd maha-admin-website
npm install
```

## 🏃 Running Locally

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## 🔐 Demo Credentials

- **Email**: `admin@maha.com`
- **Password**: `admin123`

## 📁 Project Structure

```
app/
├── login/          # Admin authentication page
├── dashboard/      # KPI & analytics dashboard
├── pipeline/       # Kanban board view
├── leads/          # Lead management table
└── page.tsx        # Root redirect
```

## 🎨 Customization

- Colors: Edit Tailwind classes (orange, teal, green, red themes)
- Data: Replace `mockLeads`, `chartData`, `stageData` with API calls
- Auth: Implement real authentication (currently hardcoded)

## 🚀 Deployment

Deploy to Vercel with one click:

```bash
npm install -g vercel
vercel
```

## 📝 Next Steps

- [ ] Connect to backend API for leads
- [ ] Implement real authentication
- [ ] Add drag-drop functionality to Kanban
- [ ] Create lead detail pages
- [ ] Add activity/notes tracking
- [ ] Implement export to Excel
- [ ] Add email notifications
