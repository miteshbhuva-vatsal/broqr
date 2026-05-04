export type FirestoreTimestamp = { _seconds: number; _nanoseconds: number }

export type ListingStatus = 'active' | 'inactive' | 'sold' | 'pending_review' | 'rejected'

export interface Listing {
  id: string
  brokerUid: string
  brokerName: string
  brokerPhone?: string
  category: string
  city: string
  location: string
  area: number
  areaUnit: string
  price: number
  originalPrice?: number
  heroImageUrl?: string
  additionalImageUrls?: string[]
  posterUrl?: string
  status: ListingStatus
  visibility: string
  description?: string
  propertyType?: string
  likesCount: number
  viewsCount: number
  commentsCount: number
  createdAt: FirestoreTimestamp | string
  updatedAt?: FirestoreTimestamp | string
  rejectionReason?: string
}

export interface AppUser {
  uid: string
  name: string
  email?: string
  mobile?: string
  city?: string
  photoUrl?: string
  role: 'broker' | 'admin' | 'viewer'
  reraNumber?: string
  referralCode?: string
  isVerified: boolean
  isProfileComplete: boolean
  listingsCount: number
  connectionsCount: number
  createdAt: FirestoreTimestamp | string
  lastSeen?: FirestoreTimestamp | string
  isBanned?: boolean
}

export interface Category {
  id: string
  name: string
  emoji: string
  label: string
  isActive: boolean
  sortOrder: number
  fields: CategoryField[]
}

export interface CategoryField {
  id: string
  label: string
  type: 'text' | 'number' | 'select' | 'boolean'
  options?: string[]
  required: boolean
}

export interface SubscriptionPlan {
  id: string
  name: string
  price: number
  durationDays: number
  maxListings: number
  features: string[]
  isActive: boolean
  sortOrder: number
}

export interface UserSubscription {
  id: string
  userId: string
  userName: string
  planId: string
  planName: string
  startDate: FirestoreTimestamp | string
  endDate: FirestoreTimestamp | string
  isActive: boolean
  paymentId?: string
  amountPaid: number
}

export interface DailyAnalytics {
  date: string        // 'YYYY-MM-DD'
  dau: number
  newUsers: number
  newListings: number
  appOpens: number
}

export interface WhatsAppTemplate {
  id: string
  name: string
  body: string
  trigger: 'listing_approved' | 'listing_rejected' | 'new_lead' | 'subscription_expiry' | 'manual'
  isActive: boolean
}
