'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/useAuth';
import { useLeadStore } from '@/stores/lead-store';
import { useAppStore } from '@/stores/app-store';
import { Lead, CreateLeadInput, UpdateLeadInput } from '@/types/lead';
import { LeadSource, LeadSourceConfig } from '@/types/common';
import { Card, CardBody, CardHeader } from '@/components/Card';
import { Button } from '@/components/Button';
import { Input } from '@/components/Input';
import { Select } from '@/components/Select';
import { Textarea } from '@/components/Textarea';
import { ArrowLeft } from 'lucide-react';

interface LeadFormProps {
  lead?: Lead;
  onSubmit?: (leadId: string) => void;
}

export function LeadForm({ lead, onSubmit }: LeadFormProps) {
  const [formData, setFormData] = useState<UpdateLeadInput>({
    name: lead?.name || '',
    phone: lead?.phone || '',
    email: lead?.email || '',
    address: lead?.address || '',
    serviceInterest: lead?.serviceInterest || '',
    source: lead?.source || LeadSource.Other,
    notes: lead?.notes || '',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const { user } = useAuth();
  const { createLead, updateLead, isLoading } = useLeadStore();
  const { addNotification } = useAppStore();
  const router = useRouter();

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    if (!formData.name) newErrors.name = 'Name is required';
    if (!formData.phone) newErrors.phone = 'Phone is required';
    if (formData.phone && formData.phone.length < 10) newErrors.phone = 'Phone must be at least 10 digits';
    return newErrors;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const newErrors = validateForm();

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    try {
      if (lead) {
        await updateLead(lead.id, formData, user!.uid, user!.name);
        addNotification({ type: 'success', message: 'Lead updated successfully!' });
      } else {
        const leadId = await createLead(
          {
            name: formData.name!,
            phone: formData.phone!,
            email: formData.email,
            address: formData.address,
            serviceInterest: formData.serviceInterest,
            source: formData.source,
            notes: formData.notes,
          },
          user!.uid,
          user!.name
        );
        addNotification({ type: 'success', message: 'Lead created successfully!' });
        onSubmit?.(leadId);
        router.push(`/leads/${leadId}`);
        return;
      }
      router.push('/leads');
    } catch (error: any) {
      addNotification({ type: 'error', message: error.message || 'Failed to save lead' });
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <button
          onClick={() => router.back()}
          className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition"
        >
          <ArrowLeft size={24} className="text-gray-600 dark:text-gray-400" />
        </button>
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            {lead ? 'Edit Lead' : 'Create New Lead'}
          </h1>
          <p className="text-gray-600 dark:text-gray-400 mt-1">
            {lead ? 'Update lead information' : 'Add a new lead to your pipeline'}
          </p>
        </div>
      </div>

      <Card>
        <CardBody>
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <Input
                label="Full Name *"
                value={formData.name}
                onChange={(e) => {
                  setFormData({ ...formData, name: e.target.value });
                  if (errors.name) setErrors({ ...errors, name: '' });
                }}
                error={errors.name}
                placeholder="John Doe"
              />

              <Input
                label="Phone Number *"
                value={formData.phone}
                onChange={(e) => {
                  setFormData({ ...formData, phone: e.target.value });
                  if (errors.phone) setErrors({ ...errors, phone: '' });
                }}
                error={errors.phone}
                placeholder="+91 9876543210"
              />

              <Input
                label="Email Address"
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                placeholder="john@example.com"
              />

              <Input
                label="Service Interest"
                value={formData.serviceInterest}
                onChange={(e) => setFormData({ ...formData, serviceInterest: e.target.value })}
                placeholder="Maintenance Contract"
              />

              <Input
                label="Address"
                value={formData.address}
                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                placeholder="123 Main St, City, State"
              />

              <Select
                label="Lead Source"
                options={Object.entries(LeadSourceConfig).map(([key, label]) => ({
                  value: key,
                  label,
                }))}
                value={formData.source || ''}
                onChange={(e) => setFormData({ ...formData, source: e.target.value as LeadSource })}
              />
            </div>

            <Textarea
              label="Notes"
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              placeholder="Additional notes about this lead..."
              rows={5}
            />

            <div className="flex gap-3 justify-end pt-6 border-t border-gray-200 dark:border-gray-700">
              <Button variant="outline" onClick={() => router.back()} type="button">
                Cancel
              </Button>
              <Button type="submit" isLoading={isLoading}>
                {lead ? 'Update Lead' : 'Create Lead'}
              </Button>
            </div>
          </form>
        </CardBody>
      </Card>
    </div>
  );
}
