import { FollowUpMethod } from './common';

export interface FollowUp {
  id: string;
  leadId: string;
  scheduledFor: Date;
  method: FollowUpMethod;
  remarks?: string;
  isCompleted: boolean;
  completedAt?: Date;
  createdByUid: string;
  createdAt: Date;
}

export interface CreateFollowUpInput {
  scheduledFor: Date;
  method: FollowUpMethod;
  remarks?: string;
}
