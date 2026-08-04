'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useLeadStore } from '@/stores/lead-store';
import { useAuth } from '@/hooks/useAuth';
import { useAppStore } from '@/stores/app-store';
import { Card, CardBody, CardHeader } from '@/components/Card';
import { Badge } from '@/components/Badge';
import { Button } from '@/components/Button';
import { Select } from '@/components/Select';
import { Modal } from '@/components/Modal';
import { Textarea } from '@/components/Textarea';
import { LoadingSpinner } from '@/components/LoadingSpinner';
import { LeadStageConfig } from '@/types/common';
import { LeadStage } from '@/types/common';
import { ArrowLeft, Trash2, Edit2 } from 'lucide-react';
import Link from 'next/link';
import { changeLeadStage } from '@/lib/firebase/leads';
import { addNoteActivity } from '@/lib/firebase/activities';
import { subscribeToActivities } from '@/lib/firebase/activities';
import { Activity } from '@/types/activity';

export default function LeadDetailPage() {
  const params = useParams();
  const router = useRouter();
  const leadId = params.id as string;
  const [activities, setActivities] = useState<Activity[]>([]);
  const [deleteConfirm, setDeleteConfirm] = useState(false);
  const [newStage, setNewStage] = useState<LeadStage | ''>('');
  const [noteText, setNoteText] = useState('');
  const [addingNote, setAddingNote] = useState(false);

  const { user } = useAuth();
  const { selectedLead, fetchLead, isLoading, deleteLead, changeStage } = useLeadStore();
  const { addNotification } = useAppStore();

  useEffect(() => {
    if (leadId) {
      fetchLead(leadId);
    }
  }, [leadId, fetchLead]);

  useEffect(() => {
    if (leadId) {
      const unsubscribe = subscribeToActivities(leadId, setActivities);
      return () => unsubscribe();
    }
  }, [leadId]);

  const handleChangeStage = async () => {
    if (!newStage || !selectedLead) return;
    try {
      await changeStage(selectedLead.id, newStage as LeadStage, user!.uid, user!.name);
      addNotification({ type: 'success', message: 'Stage updated!' });
      setNewStage('');
    } catch (error: any) {
      addNotification({ type: 'error', message: 'Failed to update stage' });
    }
  };

  const handleAddNote = async () => {
    if (!noteText || !selectedLead) return;
    try {
      setAddingNote(true);
      await addNoteActivity(selectedLead.id, noteText, user!.uid, user!.name);
      addNotification({ type: 'success', message: 'Note added!' });
      setNoteText('');
    } catch (error: any) {
      addNotification({ type: 'error', message: 'Failed to add note' });
    } finally {
      setAddingNote(false);
    }
  };

  const handleDelete = async () => {
    try {
      await deleteLead(leadId);
      addNotification({ type: 'success', message: 'Lead deleted!' });
      router.push('/leads');
    } catch (error: any) {
      addNotification({ type: 'error', message: 'Failed to delete lead' });
    }
  };

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (!selectedLead) {
    return <div className="text-center py-12">Lead not found</div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <button
          onClick={() => router.back()}
          className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"
        >
          <ArrowLeft size={24} />
        </button>
        <div className="flex-1">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">{selectedLead.name}</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-1">{selectedLead.phone}</p>
        </div>
        <div className="flex gap-2">
          <Link href={`/leads/${leadId}/edit`}>
            <Button className="gap-2">
              <Edit2 size={16} />
              Edit
            </Button>
          </Link>
          <Button variant="danger" onClick={() => setDeleteConfirm(true)}>
            <Trash2 size={16} />
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Lead Info */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Information</h2>
          </CardHeader>
          <CardBody className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Email</p>
                <p className="font-medium text-gray-900 dark:text-white">{selectedLead.email || '-'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Phone</p>
                <p className="font-medium text-gray-900 dark:text-white">{selectedLead.phone}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Address</p>
                <p className="font-medium text-gray-900 dark:text-white">{selectedLead.address || '-'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Service Interest</p>
                <p className="font-medium text-gray-900 dark:text-white">{selectedLead.serviceInterest || '-'}</p>
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Stage Card */}
        <Card>
          <CardHeader>
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Pipeline</h2>
          </CardHeader>
          <CardBody className="space-y-4">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">Current Stage</p>
              <Badge variant="stage" value={selectedLead.stage} />
            </div>

            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">Change Stage</p>
              <Select
                options={Object.entries(LeadStageConfig).map(([key, config]) => ({
                  value: key,
                  label: config.label,
                }))}
                value={newStage}
                onChange={(e) => setNewStage(e.target.value as LeadStage)}
              />
              <Button
                onClick={handleChangeStage}
                disabled={!newStage || newStage === selectedLead.stage}
                className="w-full mt-2"
              >
                Update
              </Button>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Add Note */}
      <Card>
        <CardHeader>
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Add Note</h2>
        </CardHeader>
        <CardBody className="space-y-3">
          <Textarea
            value={noteText}
            onChange={(e) => setNoteText(e.target.value)}
            placeholder="Add a note about this lead..."
            rows={4}
          />
          <Button onClick={handleAddNote} isLoading={addingNote} disabled={!noteText}>
            Add Note
          </Button>
        </CardBody>
      </Card>

      {/* Activity Timeline */}
      <Card>
        <CardHeader>
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Activity Timeline</h2>
        </CardHeader>
        <CardBody>
          <div className="space-y-4">
            {activities.length === 0 ? (
              <p className="text-gray-500 dark:text-gray-400">No activities yet</p>
            ) : (
              activities.map((activity) => (
                <div key={activity.id} className="flex gap-4 pb-4 border-b border-gray-200 dark:border-gray-700 last:border-b-0">
                  <div className="w-2 h-2 bg-orange-500 rounded-full mt-2 flex-shrink-0" />
                  <div className="flex-1">
                    <p className="font-medium text-gray-900 dark:text-white">{activity.description}</p>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                      by {activity.performedByName} • {new Date(activity.timestamp).toLocaleString()}
                    </p>
                  </div>
                </div>
              ))
            )}
          </div>
        </CardBody>
      </Card>

      {/* Delete Modal */}
      <Modal isOpen={deleteConfirm} onClose={() => setDeleteConfirm(false)} title="Delete Lead">
        <p className="text-gray-600 dark:text-gray-400 mb-6">
          Are you sure you want to delete this lead? This action cannot be undone.
        </p>
        <div className="flex gap-3 justify-end">
          <Button variant="outline" onClick={() => setDeleteConfirm(false)}>
            Cancel
          </Button>
          <Button variant="danger" onClick={handleDelete}>
            Delete
          </Button>
        </div>
      </Modal>
    </div>
  );
}
