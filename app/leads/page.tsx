'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useLeads } from '@/hooks/useLeads';
import { useAuth } from '@/hooks/useAuth';
import { useLeadStore } from '@/stores/lead-store';
import { useAppStore } from '@/stores/app-store';
import { Card, CardBody, CardHeader } from '@/components/Card';
import { Table } from '@/components/Table';
import { Badge } from '@/components/Badge';
import { Button } from '@/components/Button';
import { Input } from '@/components/Input';
import { Select } from '@/components/Select';
import { Modal } from '@/components/Modal';
import { LeadStage, LeadStageConfig } from '@/types/common';
import { Trash2, Plus, LayoutList, Columns3 } from 'lucide-react';

export default function LeadsPage() {
  const [viewMode, setViewMode] = useState<'list' | 'kanban'>('list');
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const { user } = useAuth();
  const { leads, filters, isLoading } = useLeads(user?.uid);
  const { setFilters, deleteLead } = useLeadStore();
  const { addNotification } = useAppStore();

  const handleDeleteLead = async (leadId: string) => {
    try {
      await deleteLead(leadId);
      addNotification({ type: 'success', message: 'Lead deleted successfully!' });
      setDeleteConfirm(null);
    } catch (error: any) {
      addNotification({ type: 'error', message: 'Failed to delete lead' });
    }
  };

  const leadsGroupedByStage = Object.values(LeadStage).reduce(
    (acc, stage) => {
      acc[stage] = leads.filter((l) => l.stage === stage);
      return acc;
    },
    {} as Record<LeadStage, typeof leads>
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Leads Management</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-1">Manage and track your sales leads</p>
        </div>
        <Link href="/leads/new">
          <Button className="gap-2">
            <Plus size={20} />
            Add Lead
          </Button>
        </Link>
      </div>

      {/* Filters */}
      <Card>
        <CardBody className="flex flex-col md:flex-row gap-4">
          <div className="flex-1">
            <Input
              placeholder="Search by name, phone, or email..."
              value={filters.search}
              onChange={(e) => setFilters({ search: e.target.value })}
            />
          </div>
          <Select
            options={[
              { value: '', label: 'All Stages' },
              ...Object.entries(LeadStageConfig).map(([key, config]) => ({
                value: key,
                label: config.label,
              })),
            ]}
            value={filters.stage || ''}
            onChange={(e) => setFilters({ stage: (e.target.value as LeadStage) || null })}
          />
          <div className="flex gap-2">
            <Button
              variant={viewMode === 'list' ? 'primary' : 'outline'}
              size="sm"
              onClick={() => setViewMode('list')}
              className="gap-2"
            >
              <LayoutList size={16} />
              List
            </Button>
            <Button
              variant={viewMode === 'kanban' ? 'primary' : 'outline'}
              size="sm"
              onClick={() => setViewMode('kanban')}
              className="gap-2"
            >
              <Columns3 size={16} />
              Kanban
            </Button>
          </div>
        </CardBody>
      </Card>

      {/* List View */}
      {viewMode === 'list' && (
        <Card>
          <CardHeader>
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
              Leads ({leads.length})
            </h2>
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
                {
                  key: 'id',
                  label: 'Actions',
                  render: (value) => (
                    <div className="flex gap-2">
                      <Link href={`/leads/${value}`}>
                        <Button variant="outline" size="sm">
                          View
                        </Button>
                      </Link>
                      <Link href={`/leads/${value}/edit`}>
                        <Button variant="outline" size="sm">
                          Edit
                        </Button>
                      </Link>
                      <Button
                        variant="danger"
                        size="sm"
                        onClick={() => setDeleteConfirm(value)}
                      >
                        <Trash2 size={16} />
                      </Button>
                    </div>
                  ),
                },
              ]}
              data={leads}
              keyExtractor={(row) => row.id}
              isLoading={isLoading}
              isEmpty={leads.length === 0}
              emptyMessage="No leads found. Create your first lead!"
            />
          </CardBody>
        </Card>
      )}

      {/* Kanban View */}
      {viewMode === 'kanban' && (
        <div className="grid grid-cols-1 lg:grid-cols-6 gap-4">
          {Object.entries(leadsGroupedByStage).map(([stage, leadsInStage]) => (
            <Card key={stage}>
              <CardHeader>
                <h3 className="font-semibold text-gray-900 dark:text-white">
                  {LeadStageConfig[stage as LeadStage].label}
                </h3>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                  {leadsInStage.length} lead{leadsInStage.length !== 1 ? 's' : ''}
                </p>
              </CardHeader>
              <CardBody>
                <div className="space-y-3">
                  {leadsInStage.map((lead) => (
                    <Link key={lead.id} href={`/leads/${lead.id}`}>
                      <div className={`p-3 rounded-lg border-2 cursor-pointer transition ${LeadStageConfig[stage as LeadStage].color} hover:shadow-md`}>
                        <p className="font-medium text-sm">{lead.name}</p>
                        <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">{lead.phone}</p>
                      </div>
                    </Link>
                  ))}
                  {leadsInStage.length === 0 && (
                    <p className="text-sm text-gray-400 text-center py-4">No leads</p>
                  )}
                </div>
              </CardBody>
            </Card>
          ))}
        </div>
      )}

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={!!deleteConfirm}
        onClose={() => setDeleteConfirm(null)}
        title="Delete Lead"
      >
        <p className="text-gray-600 dark:text-gray-400 mb-6">
          Are you sure you want to delete this lead? This action cannot be undone.
        </p>
        <div className="flex gap-3 justify-end">
          <Button variant="outline" onClick={() => setDeleteConfirm(null)}>
            Cancel
          </Button>
          <Button
            variant="danger"
            onClick={() => deleteConfirm && handleDeleteLead(deleteConfirm)}
          >
            Delete
          </Button>
        </div>
      </Modal>
    </div>
  );
}
