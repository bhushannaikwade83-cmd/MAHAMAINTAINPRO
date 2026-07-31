'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { LogOut, TrendingUp, Trophy, Target, AlertCircle } from 'lucide-react';

const mockLeads = [
  { id: 1, society: 'Green Valley Society', contact: 'Rajesh Sharma', city: 'Pune', stage: 'Discovery', value: 50000 },
  { id: 2, society: 'Sky High Towers', contact: 'Priya Patel', city: 'Mumbai', stage: 'Demo Booked', value: 75000 },
  { id: 3, society: 'Eco Living', contact: 'Amit Kumar', city: 'Bangalore', stage: 'Proposal Sent', value: 100000 },
];

const chartData = [
  { month: 'Jan', value: 25000 },
  { month: 'Feb', value: 35000 },
  { month: 'Mar', value: 45000 },
  { month: 'Apr', value: 55000 },
  { month: 'May', value: 65000 },
  { month: 'Jun', value: 85000 },
];

const stageData = [
  { name: 'Lead', value: 12, color: '#9CA3AF' },
  { name: 'Discovery', value: 8, color: '#14B8A6' },
  { name: 'Demo', value: 5, color: '#F97316' },
  { name: 'Proposal', value: 4, color: '#6366F1' },
  { name: 'Won', value: 3, color: '#10B981' },
];

export default function DashboardPage() {
  const router = useRouter();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const auth = localStorage.getItem('adminAuth');
    if (!auth) {
      router.push('/login');
    } else {
      setIsAuthenticated(true);
      setLoading(false);
    }
  }, [router]);

  const handleLogout = () => {
    localStorage.removeItem('adminAuth');
    router.push('/login');
  };

  if (loading) return <div className="flex items-center justify-center h-screen">Loading...</div>;
  if (!isAuthenticated) return null;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">
              MahaMaintain <span className="text-orange-500">CRM</span>
            </h1>
            <p className="text-sm text-gray-500">Admin Dashboard</p>
          </div>
          <button
            onClick={handleLogout}
            className="flex items-center gap-2 bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-lg transition"
          >
            <LogOut size={18} />
            Logout
          </button>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <nav className="flex gap-8">
            <a href="/dashboard" className="py-4 px-1 border-b-2 border-orange-500 text-orange-600 font-medium">
              Dashboard
            </a>
            <a href="/pipeline" className="py-4 px-1 border-b-2 border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300">
              Pipeline
            </a>
            <a href="/leads" className="py-4 px-1 border-b-2 border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300">
              Leads
            </a>
          </nav>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* KPI Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-500 text-sm">Open Pipeline</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">₹45.2L</p>
              </div>
              <TrendingUp className="text-teal-500" size={32} />
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-500 text-sm">Won This Month</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">₹25L</p>
              </div>
              <Trophy className="text-green-500" size={32} />
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-500 text-sm">Win Rate</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">68%</p>
              </div>
              <Target className="text-orange-500" size={32} />
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-500 text-sm">Overdue Follow-ups</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">4</p>
              </div>
              <AlertCircle className="text-red-500" size={32} />
            </div>
          </div>
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
          {/* Revenue Trend */}
          <div className="lg:col-span-2 bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Monthly Revenue</h2>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip formatter={(value) => `₹${value}`} />
                <Line type="monotone" dataKey="value" stroke="#F97316" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Pipeline Distribution */}
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Pipeline Stages</h2>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie data={stageData} cx="50%" cy="50%" labelLine={false} label={({ name, value }) => `${name}: ${value}`} outerRadius={80} dataKey="value">
                  {stageData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Recent Leads */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Recent Leads</h2>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-4 py-3 text-left text-gray-600 font-medium">Society</th>
                  <th className="px-4 py-3 text-left text-gray-600 font-medium">Contact</th>
                  <th className="px-4 py-3 text-left text-gray-600 font-medium">City</th>
                  <th className="px-4 py-3 text-left text-gray-600 font-medium">Stage</th>
                  <th className="px-4 py-3 text-left text-gray-600 font-medium">Value</th>
                </tr>
              </thead>
              <tbody>
                {mockLeads.map((lead) => (
                  <tr key={lead.id} className="border-b border-gray-200 hover:bg-gray-50">
                    <td className="px-4 py-3 text-gray-900 font-medium">{lead.society}</td>
                    <td className="px-4 py-3 text-gray-700">{lead.contact}</td>
                    <td className="px-4 py-3 text-gray-700">{lead.city}</td>
                    <td className="px-4 py-3">
                      <span className="inline-block bg-orange-100 text-orange-800 px-3 py-1 rounded-full text-xs font-medium">
                        {lead.stage}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-900 font-medium">₹{(lead.value / 100000).toFixed(1)}L</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
