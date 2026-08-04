import { LeadStage, LeadSource } from './common';

export interface Lead {
  id: string;
  name: string;
  phone: string;
  email?: string;
  address?: string;
  serviceInterest?: string;
  stage: LeadStage;
  source: LeadSource;
  assignedToUid?: string;
  assignedToName?: string;
  createdByUid: string;
  createdByName?: string;
  createdAt: Date;
  updatedAt: Date;
  nextFollowUpAt?: Date;
  notes?: string;
  attachmentUrls: string[];
  nameLower: string;
}

export interface CreateLeadInput {
  name: string;
  phone: string;
  email?: string;
  address?: string;
  serviceInterest?: string;
  source?: LeadSource;
  notes?: string;
}

export interface UpdateLeadInput {
  name?: string;
  phone?: string;
  email?: string;
  address?: string;
  serviceInterest?: string;
  stage?: LeadStage;
  source?: LeadSource;
  notes?: string;
}
