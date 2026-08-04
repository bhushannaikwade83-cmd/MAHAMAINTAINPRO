import { useEffect } from 'react';
import { useLeadStore } from '@/stores/lead-store';
import { subscribeToLeads } from '@/lib/firebase/leads';

export function useLeads(assignedToUid?: string) {
  const { leads, filters, isLoading, error, setLeads, setIsLoading } = useLeadStore();

  useEffect(() => {
    setIsLoading(true);
    const unsubscribe = subscribeToLeads(
      (leads) => {
        setLeads(leads);
        setIsLoading(false);
      },
      {
        stage: filters.stage || undefined,
        search: filters.search,
        assignedToUid,
      }
    );

    return () => unsubscribe();
  }, [filters.stage, filters.search, assignedToUid, setLeads, setIsLoading]);

  return { leads, filters, isLoading, error };
}
