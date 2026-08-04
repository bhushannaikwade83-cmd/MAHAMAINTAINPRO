import {
  collection,
  doc,
  addDoc,
  updateDoc,
  getDocs,
  query,
  where,
  orderBy,
  onSnapshot,
  Timestamp,
  Query,
} from 'firebase/firestore';
import { db } from './config';
import { FollowUp, CreateFollowUpInput } from '@/types/followup';
import { ActivityType } from '@/types/common';

export async function createFollowUp(
  leadId: string,
  input: CreateFollowUpInput,
  userId: string,
  userName: string
): Promise<string> {
  try {
    const followUpRef = await addDoc(collection(db, `leads/${leadId}/followups`), {
      leadId,
      scheduledFor: Timestamp.fromDate(input.scheduledFor),
      method: input.method,
      remarks: input.remarks || null,
      isCompleted: false,
      createdByUid: userId,
      createdAt: Timestamp.now(),
    });

    // Log activity
    await addDoc(collection(db, `leads/${leadId}/activities`), {
      type: ActivityType.FollowUpScheduled,
      description: `Follow-up scheduled for ${input.scheduledFor.toLocaleDateString()}`,
      performedByUid: userId,
      performedByName: userName,
      timestamp: Timestamp.now(),
    });

    return followUpRef.id;
  } catch (error) {
    console.error('Create follow-up error:', error);
    throw error;
  }
}

export async function completeFollowUp(
  leadId: string,
  followUpId: string,
  userId: string,
  userName: string
): Promise<void> {
  try {
    await updateDoc(doc(db, `leads/${leadId}/followups/${followUpId}`), {
      isCompleted: true,
      completedAt: Timestamp.now(),
    });

    await addDoc(collection(db, `leads/${leadId}/activities`), {
      type: ActivityType.FollowUpCompleted,
      description: 'Follow-up marked as completed',
      performedByUid: userId,
      performedByName: userName,
      timestamp: Timestamp.now(),
    });
  } catch (error) {
    console.error('Complete follow-up error:', error);
    throw error;
  }
}

export async function getFollowUps(leadId: string): Promise<FollowUp[]> {
  try {
    const q = query(
      collection(db, `leads/${leadId}/followups`),
      orderBy('scheduledFor', 'asc')
    );

    const snapshot = await getDocs(q);
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        leadId,
        scheduledFor: data.scheduledFor?.toDate() || new Date(),
        method: data.method,
        remarks: data.remarks,
        isCompleted: data.isCompleted,
        completedAt: data.completedAt?.toDate(),
        createdByUid: data.createdByUid,
        createdAt: data.createdAt?.toDate() || new Date(),
      } as FollowUp;
    });
  } catch (error) {
    console.error('Get follow-ups error:', error);
    throw error;
  }
}

export function subscribeToFollowUps(leadId: string, callback: (followUps: FollowUp[]) => void) {
  try {
    const q = query(
      collection(db, `leads/${leadId}/followups`),
      orderBy('scheduledFor', 'asc')
    );

    return onSnapshot(q, (snapshot) => {
      const followUps = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          leadId,
          scheduledFor: data.scheduledFor?.toDate() || new Date(),
          method: data.method,
          remarks: data.remarks,
          isCompleted: data.isCompleted,
          completedAt: data.completedAt?.toDate(),
          createdByUid: data.createdByUid,
          createdAt: data.createdAt?.toDate() || new Date(),
        } as FollowUp;
      });

      callback(followUps);
    });
  } catch (error) {
    console.error('Subscribe to follow-ups error:', error);
    return () => {};
  }
}

export async function getUpcomingFollowUps(userId?: string): Promise<FollowUp[]> {
  try {
    const now = new Date();
    const q = query(
      collection(db, 'leads'),
      where('assignedToUid', '==', userId || ''),
    );

    const leadsSnapshot = await getDocs(q);
    const allFollowUps: FollowUp[] = [];

    for (const leadDoc of leadsSnapshot.docs) {
      const followUpsQuery = query(
        collection(db, `leads/${leadDoc.id}/followups`),
        where('isCompleted', '==', false),
        where('scheduledFor', '>=', Timestamp.fromDate(now)),
        orderBy('scheduledFor', 'asc')
      );

      const followUpsSnapshot = await getDocs(followUpsQuery);
      followUpsSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        allFollowUps.push({
          id: doc.id,
          leadId: leadDoc.id,
          scheduledFor: data.scheduledFor?.toDate() || new Date(),
          method: data.method,
          remarks: data.remarks,
          isCompleted: data.isCompleted,
          completedAt: data.completedAt?.toDate(),
          createdByUid: data.createdByUid,
          createdAt: data.createdAt?.toDate() || new Date(),
        });
      });
    }

    return allFollowUps.sort((a, b) => a.scheduledFor.getTime() - b.scheduledFor.getTime());
  } catch (error) {
    console.error('Get upcoming follow-ups error:', error);
    return [];
  }
}
