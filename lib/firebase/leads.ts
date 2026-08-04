import { Lead, CreateLeadInput, UpdateLeadInput } from '@/types/lead';
import { LeadStage, LeadSource, ActivityType } from '@/types/common';

// Mock data
const mockLeads: Lead[] = [
  {
    id: '1',
    name: 'Rajesh Sharma',
    phone: '9876543210',
    email: 'rajesh@example.com',
    address: 'Green Valley Society, Pune',
    serviceInterest: 'Maintenance Contract',
    stage: LeadStage.Contacted,
    source: LeadSource.Referral,
    assignedToUid: 'user1',
    assignedToName: 'You',
    createdByUid: 'user1',
    createdByName: 'You',
    createdAt: new Date('2024-01-15'),
    updatedAt: new Date('2024-01-20'),
    notes: 'Interested in annual maintenance',
    attachmentUrls: [],
    nameLower: 'rajesh sharma',
  },
  {
    id: '2',
    name: 'Priya Patel',
    phone: '8765432109',
    email: 'priya@example.com',
    address: 'Sky High Towers, Mumbai',
    serviceInterest: 'Regular Cleaning',
    stage: LeadStage.ProposalSent,
    source: LeadSource.Website,
    assignedToUid: 'user1',
    assignedToName: 'You',
    createdByUid: 'user1',
    createdByName: 'You',
    createdAt: new Date('2024-01-18'),
    updatedAt: new Date('2024-01-22'),
    notes: 'Waiting for approval from committee',
    attachmentUrls: [],
    nameLower: 'priya patel',
  },
  {
    id: '3',
    name: 'Amit Kumar',
    phone: '7654321098',
    email: 'amit@example.com',
    address: 'Eco Living, Bangalore',
    serviceInterest: 'Pest Control',
    stage: LeadStage.Won,
    source: LeadSource.Referral,
    assignedToUid: 'user1',
    assignedToName: 'You',
    createdByUid: 'user1',
    createdByName: 'You',
    createdAt: new Date('2024-01-10'),
    updatedAt: new Date('2024-01-25'),
    notes: 'Contract signed',
    attachmentUrls: [],
    nameLower: 'amit kumar',
  },
  {
    id: '4',
    name: 'Neha Singh',
    phone: '6543210987',
    email: 'neha@example.com',
    address: 'Premium Heights, Delhi',
    serviceInterest: 'Electrical Maintenance',
    stage: LeadStage.New,
    source: LeadSource.PhoneCall,
    assignedToUid: 'user1',
    assignedToName: 'You',
    createdByUid: 'user1',
    createdByName: 'You',
    createdAt: new Date('2024-01-28'),
    updatedAt: new Date('2024-01-28'),
    notes: 'Initial inquiry received',
    attachmentUrls: [],
    nameLower: 'neha singh',
  },
  {
    id: '5',
    name: 'Sanjay Gupta',
    phone: '5432109876',
    email: 'sanjay@example.com',
    address: 'Modern Residency, Pune',
    serviceInterest: 'Water Tank Cleaning',
    stage: LeadStage.Qualified,
    source: LeadSource.Advertisement,
    assignedToUid: 'user1',
    assignedToName: 'You',
    createdByUid: 'user1',
    createdByName: 'You',
    createdAt: new Date('2024-01-12'),
    updatedAt: new Date('2024-01-24'),
    notes: 'Qualified lead, schedule demo',
    attachmentUrls: [],
    nameLower: 'sanjay gupta',
  },
];

let demoLeads = [...mockLeads];

export async function createLead(
  input: CreateLeadInput,
  userId: string,
  userName: string
): Promise<string> {
  const id = Math.random().toString(36).substring(7);
  const newLead: Lead = {
    id,
    name: input.name,
    nameLower: input.name.toLowerCase(),
    phone: input.phone,
    email: input.email,
    address: input.address,
    serviceInterest: input.serviceInterest,
    stage: LeadStage.New,
    source: input.source || LeadSource.Other,
    assignedToUid: userId,
    assignedToName: userName,
    createdByUid: userId,
    createdByName: userName,
    createdAt: new Date(),
    updatedAt: new Date(),
    notes: input.notes,
    attachmentUrls: [],
  };
  demoLeads.push(newLead);
  return id;
}

export async function updateLead(
  leadId: string,
  input: UpdateLeadInput,
  userId: string,
  userName: string
): Promise<void> {
  const leadIndex = demoLeads.findIndex((l) => l.id === leadId);
  if (leadIndex !== -1) {
    const lead = demoLeads[leadIndex];
    demoLeads[leadIndex] = {
      ...lead,
      name: input.name || lead.name,
      nameLower: (input.name || lead.name).toLowerCase(),
      phone: input.phone || lead.phone,
      email: input.email !== undefined ? input.email : lead.email,
      address: input.address !== undefined ? input.address : lead.address,
      serviceInterest: input.serviceInterest !== undefined ? input.serviceInterest : lead.serviceInterest,
      source: input.source || lead.source,
      notes: input.notes !== undefined ? input.notes : lead.notes,
      updatedAt: new Date(),
    };
  }
}

export async function deleteLead(leadId: string): Promise<void> {
  demoLeads = demoLeads.filter((l) => l.id !== leadId);
}

export async function getLead(leadId: string): Promise<Lead | null> {
  return demoLeads.find((l) => l.id === leadId) || null;
}

export async function getLeads(filters?: {
  stage?: LeadStage;
  assignedToUid?: string;
  search?: string;
}): Promise<Lead[]> {
  let result = [...demoLeads];

  if (filters?.stage) {
    result = result.filter((l) => l.stage === filters.stage);
  }

  if (filters?.assignedToUid) {
    result = result.filter((l) => l.assignedToUid === filters.assignedToUid);
  }

  if (filters?.search) {
    const searchLower = filters.search.toLowerCase();
    result = result.filter(
      (l) =>
        l.nameLower.includes(searchLower) ||
        l.phone.includes(searchLower) ||
        l.email?.toLowerCase().includes(searchLower)
    );
  }

  return result.sort((a, b) => b.updatedAt.getTime() - a.updatedAt.getTime());
}

export async function changeLeadStage(
  leadId: string,
  newStage: LeadStage,
  userId: string,
  userName: string
): Promise<void> {
  const leadIndex = demoLeads.findIndex((l) => l.id === leadId);
  if (leadIndex !== -1) {
    demoLeads[leadIndex] = {
      ...demoLeads[leadIndex],
      stage: newStage,
      updatedAt: new Date(),
    };
  }
}

export async function uploadLeadAttachment(
  leadId: string,
  file: File
): Promise<string> {
  const url = URL.createObjectURL(file);
  const leadIndex = demoLeads.findIndex((l) => l.id === leadId);
  if (leadIndex !== -1) {
    demoLeads[leadIndex].attachmentUrls.push(url);
  }
  return url;
}

export async function deleteLeadAttachment(
  leadId: string,
  attachmentUrl: string
): Promise<void> {
  const leadIndex = demoLeads.findIndex((l) => l.id === leadId);
  if (leadIndex !== -1) {
    demoLeads[leadIndex].attachmentUrls = demoLeads[leadIndex].attachmentUrls.filter(
      (url) => url !== attachmentUrl
    );
  }
}

export function subscribeToLeads(
  callback: (leads: Lead[]) => void,
  filters?: { stage?: LeadStage; assignedToUid?: string; search?: string }
) {
  getLeads(filters).then(callback);

  // Simulate real-time updates
  const interval = setInterval(() => {
    getLeads(filters).then(callback);
  }, 1000);

  return () => clearInterval(interval);
}
