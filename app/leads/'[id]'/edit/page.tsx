'use client';

import { useEffect } from 'react';
import { useParams } from 'next/navigation';
import { useLeadStore } from '@/stores/lead-store';
import { LeadForm } from '@/components/leads/LeadForm';
import { LoadingSpinner } from '@/components/LoadingSpinner';

export default function EditLeadPage() {
  const params = useParams();
  const leadId = params.id as string;
  const { selectedLead, fetchLead, isLoading } = useLeadStore();

  useEffect(() => {
    if (leadId) {
      fetchLead(leadId);
    }
  }, [leadId, fetchLead]);

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (!selectedLead) {
    return <div className="text-center py-12">Lead not found</div>;
  }

  return <LeadForm lead={selectedLead} />;
}
