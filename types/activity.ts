import { ActivityType } from './common';

export interface Activity {
  id: string;
  leadId: string;
  type: ActivityType;
  description: string;
  performedByUid: string;
  performedByName: string;
  timestamp: Date;
  metadata?: Record<string, any>;
}
