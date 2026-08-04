import { create } from 'zustand';
import { Lead, CreateLeadInput, UpdateLeadInput } from '@/types/lead';
import { LeadStage } from '@/types/common';
import * as leadService from '@/lib/firebase/leads';

interface LeadFilters {
  search: string;
  stage: LeadStage | null;
}

interface LeadStore {
  leads: Lead[];
  selectedLead: Lead | null;
  filters: LeadFilters;
  isLoading: boolean;
  error: string | null;

  setLeads: (leads: Lead[]) => void;
  setSelectedLead: (lead: Lead | null) => void;
  setFilters: (filters: Partial<LeadFilters>) => void;
  setIsLoading: (isLoading: boolean) => void;
  setError: (error: string | null) => void;

  createLead: (input: CreateLeadInput, userId: string, userName: string) => Promise<string>;
  updateLead: (leadId: string, input: UpdateLeadInput, userId: string, userName: string) => Promise<void>;
  deleteLead: (leadId: string) => Promise<void>;
  changeStage: (leadId: string, newStage: LeadStage, userId: string, userName: string) => Promise<void>;
  uploadAttachment: (leadId: string, file: File) => Promise<string>;
  deleteAttachment: (leadId: string, attachmentUrl: string) => Promise<void>;
  fetchLeads: (filters?: Partial<LeadFilters>, assignedToUid?: string) => Promise<void>;
  fetchLead: (leadId: string) => Promise<void>;
}

export const useLeadStore = create<LeadStore>((set, get) => ({
  leads: [],
  selectedLead: null,
  filters: { search: '', stage: null },
  isLoading: false,
  error: null,

  setLeads: (leads) => set({ leads }),
  setSelectedLead: (lead) => set({ selectedLead: lead }),
  setFilters: (filters) => set((state) => ({ filters: { ...state.filters, ...filters } })),
  setIsLoading: (isLoading) => set({ isLoading }),
  setError: (error) => set({ error }),

  createLead: async (input, userId, userName) => {
    set({ isLoading: true, error: null });
    try {
      const leadId = await leadService.createLead(input, userId, userName);
      set({ isLoading: false });
      return leadId;
    } catch (error: any) {
      set({ error: error.message || 'Failed to create lead', isLoading: false });
      throw error;
    }
  },

  updateLead: async (leadId, input, userId, userName) => {
    set({ isLoading: true, error: null });
    try {
      await leadService.updateLead(leadId, input, userId, userName);
      set({ isLoading: false });
    } catch (error: any) {
      set({ error: error.message || 'Failed to update lead', isLoading: false });
      throw error;
    }
  },

  deleteLead: async (leadId) => {
    set({ isLoading: true, error: null });
    try {
      await leadService.deleteLead(leadId);
      set((state) => ({
        leads: state.leads.filter((l) => l.id !== leadId),
        isLoading: false,
      }));
    } catch (error: any) {
      set({ error: error.message || 'Failed to delete lead', isLoading: false });
      throw error;
    }
  },

  changeStage: async (leadId, newStage, userId, userName) => {
    set({ isLoading: true, error: null });
    try {
      await leadService.changeLeadStage(leadId, newStage, userId, userName);
      set((state) => ({
        leads: state.leads.map((l) => (l.id === leadId ? { ...l, stage: newStage } : l)),
        isLoading: false,
      }));
    } catch (error: any) {
      set({ error: error.message || 'Failed to change stage', isLoading: false });
      throw error;
    }
  },

  uploadAttachment: async (leadId, file) => {
    set({ isLoading: true, error: null });
    try {
      const url = await leadService.uploadLeadAttachment(leadId, file);
      set({ isLoading: false });
      return url;
    } catch (error: any) {
      set({ error: error.message || 'Failed to upload attachment', isLoading: false });
      throw error;
    }
  },

  deleteAttachment: async (leadId, attachmentUrl) => {
    set({ isLoading: true, error: null });
    try {
      await leadService.deleteLeadAttachment(leadId, attachmentUrl);
      set({ isLoading: false });
    } catch (error: any) {
      set({ error: error.message || 'Failed to delete attachment', isLoading: false });
      throw error;
    }
  },

  fetchLeads: async (filters, assignedToUid) => {
    set({ isLoading: true, error: null });
    try {
      const leads = await leadService.getLeads({
        stage: filters?.stage || undefined,
        assignedToUid,
        search: filters?.search,
      });
      set({ leads, isLoading: false });
    } catch (error: any) {
      set({ error: error.message || 'Failed to fetch leads', isLoading: false });
    }
  },

  fetchLead: async (leadId) => {
    set({ isLoading: true, error: null });
    try {
      const lead = await leadService.getLead(leadId);
      if (lead) {
        set({ selectedLead: lead, isLoading: false });
      }
    } catch (error: any) {
      set({ error: error.message || 'Failed to fetch lead', isLoading: false });
    }
  },
}));
