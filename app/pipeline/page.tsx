'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { LogOut, Plus, Filter } from 'lucide-react';

const stages = ['Lead', 'Discovery', 'Demo Booked', 'Proposal Sent', 'Committee Decision', 'Won', 'Lost'];

const mockCards = {
  'Lead': [
    { id: 1, society: 'New Society Project', contact: 'Vikas Singh', value: 30000 },
    { id: 2, society: 'Smart City Homes', contact: 'Deepak Rao', value: 45000 },
  ],
  'Discovery': [
    { id: 3, society: 'Green Valley', contact: 'Rajesh Sharma', value: 50000 },
  ],
  'Demo Booked': [
    { id: 4, society: 'Sky High Towers', contact: 'Priya Patel', value: 75000 },
    { id: 5, society: 'Premium Heights', contact: 'Arjun Nair', value: 55000 },
  ],
  'Proposal Sent': [
    { id: 6, society: 'Eco Living', contact: 'Amit Kumar', value: 100000 },
  ],
  'Committee Decision': [
    { id: 7, society: 'Modern Residency', contact: 'Sanjay Gupta', value: 85000 },
  ],
  'Won': [
    { id: 8, society: 'Valley View', contact: 'Neha Singh', value: 120000 },
  ],
  'Lost': [
    { id: 9, society: 'Budget Colony', contact: 'Rahul Verma', value: 20000 },
  ],
};

const stageColors = {
  'Lead': 'bg-gray-100',
  'Discovery': 'bg-teal-50',
  'Demo Booked': 'bg-orange-50',
  'Proposal Sent': 'bg-indigo-50',
  'Committee Decision': 'bg-yellow-50',
  'Won': 'bg-green-50',
  'Lost': 'bg-red-50',
};

export default function PipelinePage() {
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
            <p className="text-sm text-gray-500">Sales Pipeline</p>
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
            <a href="/dashboard" className="py-4 px-1 border-b-2 border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300">
              Dashboard
            </a>
            <a href="/pipeline" className="py-4 px-1 border-b-2 border-orange-500 text-orange-600 font-medium">
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
        {/* Filters */}
        <div className="mb-6 flex justify-between items-center">
          <h2 className="text-xl font-semibold text-gray-900">Kanban View</h2>
          <div className="flex gap-2">
            <button className="flex items-center gap-2 bg-white text-gray-700 px-4 py-2 rounded-lg border border-gray-300 hover:bg-gray-50">
              <Filter size={18} />
              Filter
            </button>
            <button className="flex items-center gap-2 bg-orange-500 hover:bg-orange-600 text-white px-4 py-2 rounded-lg">
              <Plus size={18} />
              Add Lead
            </button>
          </div>
        </div>

        {/* Kanban Board */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 xl:grid-cols-7 gap-4 overflow-x-auto pb-4">
          {stages.map((stage) => (
            <div key={stage} className="flex-shrink-0 w-80 lg:w-72">
              <div className={`${stageColors[stage as keyof typeof stageColors]} rounded-lg p-4 min-h-96`}>
                {/* Column Header */}
                <div className="flex justify-between items-center mb-4">
                  <h3 className="font-semibold text-gray-900">{stage}</h3>
                  <span className="bg-gray-300 text-gray-700 text-xs font-bold rounded-full w-6 h-6 flex items-center justify-center">
                    {mockCards[stage as keyof typeof mockCards]?.length || 0}
                  </span>
                </div>

                {/* Cards */}
                <div className="space-y-3">
                  {mockCards[stage as keyof typeof mockCards]?.map((card) => (
                    <div
                      key={card.id}
                      className="bg-white p-3 rounded-lg shadow-sm border border-gray-200 hover:shadow-md cursor-move transition"
                    >
                      <p className="font-medium text-gray-900 text-sm">{card.society}</p>
                      <p className="text-gray-500 text-xs mt-1">{card.contact}</p>
                      <div className="mt-2 pt-2 border-t border-gray-100 flex justify-between items-center">
                        <span className="text-xs font-semibold text-orange-600">₹{(card.value / 100000).toFixed(1)}L</span>
                        <span className="text-xs text-gray-400">ID: {card.id}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
