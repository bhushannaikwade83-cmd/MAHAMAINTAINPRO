export enum UserRole {
  SuperAdmin = 'superAdmin',
  Admin = 'admin',
  SalesManager = 'salesManager',
  SalesExecutive = 'salesExecutive',
  Technician = 'technician',
  Customer = 'customer',
}

export enum Permission {
  ManageUsers = 'manageUsers',
  ManageRoles = 'manageRoles',
  ViewAllLeads = 'viewAllLeads',
  ManageOwnLeads = 'manageOwnLeads',
  AssignLeads = 'assignLeads',
  DeleteLead = 'deleteLead',
  ManageCustomers = 'manageCustomers',
  ManageSociety = 'manageSociety',
  CreateServiceRequest = 'createServiceRequest',
  AssignTechnician = 'assignTechnician',
  CompleteServiceRequest = 'completeServiceRequest',
  ViewDashboardKpis = 'viewDashboardKpis',
  ViewFinancials = 'viewFinancials',
}

export enum LeadStage {
  New = 'new',
  Contacted = 'contacted',
  Qualified = 'qualified',
  ProposalSent = 'proposalSent',
  Won = 'won',
  Lost = 'lost',
}

export const LeadStageConfig: Record<LeadStage, { label: string; color: string; isClosed: boolean }> = {
  [LeadStage.New]: { label: 'New', color: 'bg-blue-100 text-blue-800', isClosed: false },
  [LeadStage.Contacted]: { label: 'Contacted', color: 'bg-yellow-100 text-yellow-800', isClosed: false },
  [LeadStage.Qualified]: { label: 'Qualified', color: 'bg-purple-100 text-purple-800', isClosed: false },
  [LeadStage.ProposalSent]: { label: 'Proposal Sent', color: 'bg-indigo-100 text-indigo-800', isClosed: false },
  [LeadStage.Won]: { label: 'Won', color: 'bg-green-100 text-green-800', isClosed: true },
  [LeadStage.Lost]: { label: 'Lost', color: 'bg-red-100 text-red-800', isClosed: true },
};

export enum LeadSource {
  Website = 'website',
  Referral = 'referral',
  WalkIn = 'walkIn',
  PhoneCall = 'phoneCall',
  SocialMedia = 'socialMedia',
  Advertisement = 'advertisement',
  Other = 'other',
}

export const LeadSourceConfig: Record<LeadSource, string> = {
  [LeadSource.Website]: 'Website',
  [LeadSource.Referral]: 'Referral',
  [LeadSource.WalkIn]: 'Walk-in',
  [LeadSource.PhoneCall]: 'Phone Call',
  [LeadSource.SocialMedia]: 'Social Media',
  [LeadSource.Advertisement]: 'Advertisement',
  [LeadSource.Other]: 'Other',
};

export enum FollowUpMethod {
  Call = 'call',
  Visit = 'visit',
  Email = 'email',
  WhatsApp = 'whatsapp',
}

export const FollowUpMethodConfig: Record<FollowUpMethod, string> = {
  [FollowUpMethod.Call]: '☎️ Call',
  [FollowUpMethod.Visit]: '📍 Visit',
  [FollowUpMethod.Email]: '📧 Email',
  [FollowUpMethod.WhatsApp]: '💬 WhatsApp',
};

export enum ActivityType {
  Created = 'created',
  StageChanged = 'stageChanged',
  NoteAdded = 'noteAdded',
  FollowUpScheduled = 'followUpScheduled',
  FollowUpCompleted = 'followUpCompleted',
  AttachmentAdded = 'attachmentAdded',
  Assigned = 'assigned',
  CallLogged = 'callLogged',
}

export const ActivityTypeConfig: Record<ActivityType, string> = {
  [ActivityType.Created]: 'Lead Created',
  [ActivityType.StageChanged]: 'Stage Changed',
  [ActivityType.NoteAdded]: 'Note Added',
  [ActivityType.FollowUpScheduled]: 'Follow-up Scheduled',
  [ActivityType.FollowUpCompleted]: 'Follow-up Completed',
  [ActivityType.AttachmentAdded]: 'Attachment Added',
  [ActivityType.Assigned]: 'Assigned',
  [ActivityType.CallLogged]: 'Call Logged',
};
