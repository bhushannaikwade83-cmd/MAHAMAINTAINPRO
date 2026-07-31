'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { LogOut, Plus, Search, Edit2, Trash2, Eye } from 'lucide-react';

const mockAllLeads = [
  { id: 1, society: 'Green Valley Society', contact: 'Rajesh Sharma', phone: '9876543210', city: 'Pune', stage: 'Discovery', value: 50000, date: '2024-07-15' },
  { id: 2, society: 'Sky High Towers', contact: 'Priya Patel', phone: '8765432109', city: 'Mumbai', stage: 'Demo Booked', value: 75000, date: '2024-07-18' },
  { id: 3, society: 'Eco Living', contact: 'Amit Kumar', phone: '7654321098', city: 'Bangalore', stage: 'Proposal Sent', value: 100000, date: '2024-07-20' },
  { id: 4, society: 'Premium Heights', contact: 'Arjun Nair', phone: '6543210987', city: 'Hyderabad', stage: 'Committee Decision', value: 85000, date: '2024-07-22' },
  { id: 5, society: 'Valley View', contact: 'Neha Singh', phone: '5432109876', city: 'Delhi', stage: 'Won', value: 120000, date: '2024-07-25' },
  { id: 6, society: 'Modern Residency', contact: 'Sanjay Gupta', phone: '4321098765', city: 'Pune', stage: 'Lead', value: 40000, date: '2024-07-26' },
  { id: 7, society: 'Budget Colony', contact: 'Rahul Verma', phone: '3210987654', city: 'Nagpur', stage: 'Lost', value: 20000, date: '2024-07-27' },
];

const stageColors: { [key: string]: string } = {
  'Lead': 'bg-gray-100 text-gray-800',
  'Discovery': 'bg-teal-100 text-teal-800',
  'Demo Booked': 'bg-orange-100 text-orange-800',
  'Proposal Sent': 'bg-indigo-100 text-indigo-800',
  'Committee Decision': 'bg-yellow-100 text-yellow-800',
  'Won': 'bg-green-100 text-green-800',
  'Lost': 'bg-red-100 text-red-800',
};

export default function LeadsPage() {
  const router = useRouter();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [leads, setLeads] = useState(mockAllLeads);

  useEffect(() => {
    const auth = localStorage.getItem('adminAuth');
    if (!auth) {
      router.push('/login');
    } else {
      setIsAuthenticated(true);
      setLoading(false);
    }
  }, [router]);

  const filteredLeads = leads.filter(
    (lead) =>
      lead.society.toLowerCase().includes(search.toLowerCase()) ||
      lead.contact.toLowerCase().includes(search.toLowerCase()) ||
      lead.city.toLowerCase().includes(search.toLowerCase())
  );

  const handleDeleteLead = (id: number) => {
    setLeads(leads.filter((lead) => lead.id !== id));
  };

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
            <p className="text-sm text-gray-500">All Leads</p>
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
            <a href="/pipeline" className="py-4 px-1 border-b-2 border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300">
              Pipeline
            </a>
            <a href="/leads" className="py-4 px-1 border-b-2 border-orange-500 text-orange-600 font-medium">
              Leads
            </a>
          </nav>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Search & Actions */}
        <div className="mb-6 flex justify-between items-center gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
            <input
              type="text"
              placeholder="Search by society, contact, or city..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
            />
          </div>
          <button className="flex items-center gap-2 bg-orange-500 hover:bg-orange-600 text-white px-4 py-2 rounded-lg">
            <Plus size={18} />
            Add Lead
          </button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <p className="text-gray-500 text-sm">Total Leads</p>
            <p className="text-2xl font-bold text-gray-900">{leads.length}</p>
          </div>
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <p className="text-gray-500 text-sm">Total Pipeline</p>
            <p className="text-2xl font-bold text-gray-900">₹{(leads.reduce((a, b) => a + b.value, 0) / 100000).toFixed(1)}L</p>
          </div>
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <p className="text-gray-500 text-sm">Open Deals</p>
            <p className="text-2xl font-bold text-gray-900">{leads.filter((l) => l.stage !== 'Won' && l.stage !== 'Lost').length}</p>
          </div>
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <p className="text-gray-500 text-sm">Won Deals</p>
            <p className="text-2xl font-bold text-green-600">{leads.filter((l) => l.stage === 'Won').length}</p>
          </div>
        </div>

        {/* Leads Table */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-3 text-left text-gray-600 font-semibold">Society</th>
                  <th className="px-6 py-3 text-left text-gray-600 font-semibold">Contact</th>
                  <th className="px-6 py-3 text-left text-gray-600 font-semibold">Phone</th>
                  <th className="px-6 py-3 text-left text-gray-600 font-semibold">City</th>
                  <th className="px-6 py-3 text-left text-gray-600 font-semibold">Stage</th>
                  <th className="px-6 py-3 text-left text-gray-600 font-semibold">Value</th>
                  <th className="px-6 py-3 text-left text-gray-600 font-semibold">Added</th>
                  <th className="px-6 py-3 text-center text-gray-600 font-semibold">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredLeads.map((lead) => (
                  <tr key={lead.id} className="border-b border-gray-200 hover:bg-gray-50">
                    <td className="px-6 py-4 text-gray-900 font-medium">{lead.society}</td>
                    <td className="px-6 py-4 text-gray-700">{lead.contact}</td>
                    <td className="px-6 py-4 text-gray-700">{lead.phone}</td>
                    <td className="px-6 py-4 text-gray-700">{lead.city}</td>
                    <td className="px-6 py-4">
                      <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${stageColors[lead.stage]}`}>
                        {lead.stage}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-gray-900 font-semibold">₹{(lead.value / 100000).toFixed(1)}L</td>
                    <td className="px-6 py-4 text-gray-500 text-xs">{lead.date}</td>
                    <td className="px-6 py-4 text-center">
                      <div className="flex justify-center gap-2">
                        <button className="text-blue-500 hover:text-blue-700 p-1" title="View">
                          <Eye size={18} />
                        </button>
                        <button className="text-orange-500 hover:text-orange-700 p-1" title="Edit">
                          <Edit2 size={18} />
                        </button>
                        <button
                          onClick={() => handleDeleteLead(lead.id)}
                          className="text-red-500 hover:text-red-700 p-1"
                          title="Delete"
                        >
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {filteredLeads.length === 0 && (
            <div className="text-center py-8 text-gray-500">
              No leads found. Try adjusting your search.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
