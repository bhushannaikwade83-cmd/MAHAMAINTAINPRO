import { Activity } from '@/types/activity';
import { ActivityType } from '@/types/common';

const demoActivities: { [leadId: string]: Activity[] } = {
  '1': [
    {
      id: '1',
      leadId: '1',
      type: ActivityType.Created,
      description: 'Lead created',
      performedByUid: 'user1',
      performedByName: 'You',
      timestamp: new Date('2024-01-15'),
    },
    {
      id: '2',
      leadId: '1',
      type: ActivityType.StageChanged,
      description: 'Stage changed from New to Contacted',
      performedByUid: 'user1',
      performedByName: 'You',
      timestamp: new Date('2024-01-20'),
    },
  ],
  '2': [
    {
      id: '3',
      leadId: '2',
      type: ActivityType.Created,
      description: 'Lead created',
      performedByUid: 'user1',
      performedByName: 'You',
      timestamp: new Date('2024-01-18'),
    },
    {
      id: '4',
      leadId: '2',
      type: ActivityType.NoteAdded,
      description: 'Waiting for approval from committee',
      performedByUid: 'user1',
      performedByName: 'You',
      timestamp: new Date('2024-01-22'),
    },
  ],
  '3': [
    {
      id: '5',
      leadId: '3',
      type: ActivityType.Created,
      description: 'Lead created',
      performedByUid: 'user1',
      performedByName: 'You',
      timestamp: new Date('2024-01-10'),
    },
    {
      id: '6',
      leadId: '3',
      type: ActivityType.StageChanged,
      description: 'Stage changed to Won',
      performedByUid: 'user1',
      performedByName: 'You',
      timestamp: new Date('2024-01-25'),
    },
  ],
};

export async function addActivity(
  leadId: string,
  type: ActivityType,
  description: string,
  userId: string,
  userName: string,
  metadata?: Record<string, any>
): Promise<string> {
  if (!demoActivities[leadId]) {
    demoActivities[leadId] = [];
  }

  const id = Math.random().toString(36).substring(7);
  demoActivities[leadId].push({
    id,
    leadId,
    type,
    description,
    performedByUid: userId,
    performedByName: userName,
    timestamp: new Date(),
    metadata,
  });

  return id;
}

export async function getActivities(leadId: string): Promise<Activity[]> {
  return (demoActivities[leadId] || []).sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
}

export function subscribeToActivities(leadId: string, callback: (activities: Activity[]) => void) {
  getActivities(leadId).then(callback);

  const interval = setInterval(() => {
    getActivities(leadId).then(callback);
  }, 1000);

  return () => clearInterval(interval);
}

export async function addNoteActivity(
  leadId: string,
  note: string,
  userId: string,
  userName: string
): Promise<string> {
  return addActivity(leadId, ActivityType.NoteAdded, note, userId, userName);
}
