'use client';

import { useLeads } from '@/hooks/useLeads';
import { useAuth } from '@/hooks/useAuth';
import { StatCard } from '@/components/StatCard';
import { Card, CardBody, CardHeader } from '@/components/Card';
import { Table } from '@/components/Table';
import { Badge } from '@/components/Badge';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { TrendingUp, Users, CheckCircle, Calendar } from 'lucide-react';
import Link from 'next/link';
import { LeadStage } from '@/types/common';

const monthlyData = [
  { name: 'Jan', revenue: 4000 },
  { name: 'Feb', revenue: 3000 },
  { name: 'Mar', revenue: 2000 },
  { name: 'Apr', revenue: 2780 },
  { name: 'May', revenue: 1890 },
  { name: 'Jun', revenue: 2390 },
  { name: 'Jul', revenue: 3490 },
];

const stageDistribution = [
  { name: 'New', value: 45, color: '#3b82f6' },
  { name: 'Contacted', value: 30, color: '#fbbf24' },
  { name: 'Qualified', value: 25, color: '#a78bfa' },
  { name: 'Proposal Sent', value: 20, color: '#818cf8' },
  { name: 'Won', value: 35, color: '#10b981' },
  { name: 'Lost', value: 15, color: '#ef4444' },
];

export default function DashboardPage() {
  const { user } = useAuth();
  const { leads } = useLeads();

  const openLeads = leads.filter((l) => ![LeadStage.Won, LeadStage.Lost].includes(l.stage)).length;
  const wonLeads = leads.filter((l) => l.stage === LeadStage.Won).length;
  const recentLeads = leads.slice(0, 10);

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Dashboard</h1>
        <p className="text-gray-600 dark:text-gray-400">Welcome back, {user?.name}! Here's an overview of your business.</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Open Leads"
          value={openLeads}
          trend={{ direction: 'up', value: 12 }}
          icon={<TrendingUp className="w-6 h-6 text-orange-600" />}
        />
        <StatCard
          title="Active Customers"
          value="24"
          trend={{ direction: 'up', value: 8 }}
          icon={<Users className="w-6 h-6 text-orange-600" />}
        />
        <StatCard
          title="Won This Month"
          value={wonLeads}
          trend={{ direction: 'up', value: 23 }}
          icon={<CheckCircle className="w-6 h-6 text-orange-600" />}
        />
        <StatCard
          title="Pending Follow-ups"
          value="7"
          trend={{ direction: 'down', value: 4 }}
          icon={<Calendar className="w-6 h-6 text-orange-600" />}
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Revenue Chart */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Monthly Revenue</h2>
          </CardHeader>
          <CardBody>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={monthlyData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="revenue" stroke="#f97316" name="Revenue ($)" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>

        {/* Stage Distribution */}
        <Card>
          <CardHeader>
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Pipeline Distribution</h2>
          </CardHeader>
          <CardBody>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={stageDistribution}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }: any) => `${name} ${((percent || 0) * 100).toFixed(0)}%`}
                  outerRadius={100}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {stageDistribution.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>
      </div>

      {/* Recent Leads Table */}
      <Card>
        <CardHeader className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Recent Leads</h2>
          <Link href="/leads" className="text-orange-600 hover:text-orange-700 text-sm font-medium">
            View all
          </Link>
        </CardHeader>
        <CardBody>
          <Table
            columns={[
              { key: 'name', label: 'Name' },
              { key: 'phone', label: 'Phone' },
              { key: 'email', label: 'Email' },
              {
                key: 'stage',
                label: 'Stage',
                render: (value) => <Badge variant="stage" value={value} />,
              },
              {
                key: 'createdAt',
                label: 'Created',
                render: (value: Date) => new Date(value).toLocaleDateString(),
              },
            ]}
            data={recentLeads}
            keyExtractor={(row) => row.id}
            isEmpty={recentLeads.length === 0}
            emptyMessage="No leads yet"
          />
        </CardBody>
      </Card>
    </div>
  );
}
