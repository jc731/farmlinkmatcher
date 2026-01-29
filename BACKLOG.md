# Illinois Farmlink App - Development Backlog

## Overview

This backlog tracks all development work for the Illinois Farmlink App MVP. Items are organized by epic and milestone, with clear dependencies and sequencing.

## Epics

### Epic 1: Foundation & Infrastructure
**Goal**: Establish project foundation, database schema, authentication, and core infrastructure.

**Status**: In Progress

### Epic 2: User Profiles & Onboarding
**Goal**: Enable users to create profiles, complete onboarding, and manage their information.

**Status**: Not Started

### Epic 3: Admin Approval System
**Goal**: Build admin interfaces for reviewing and approving users and listings.

**Status**: Not Started

### Epic 4: Listings Management
**Goal**: Enable landowners to create, edit, and manage farmland listings with approval workflow.

**Status**: Not Started

### Epic 5: Search & Discovery
**Goal**: Allow farmers to search, filter, and view approved listings.

**Status**: Not Started

### Epic 6: Inquiries & Messaging
**Goal**: Enable farmers to express interest in listings and communicate with landowners (non-realtime).

**Status**: Not Started

## MVP Milestones

### Milestone 1: Project Setup & Documentation ✅
**Target**: Complete
**Dependencies**: None

- [x] Consult org-controller MCP for standards
- [x] Create README.md with all required sections
- [x] Create BACKLOG.md with epics and milestones
- [x] Set up org preferences (mcp/preferences.json)

**Acceptance Criteria**:
- README.md includes project purpose, architecture, tech stack, environment setup, approval workflow, role/status model
- BACKLOG.md includes epics, milestones, feature-level items, dependencies, sequencing
- All documentation follows org-controller standards

---

### Milestone 2: Database Schema & RLS Setup ✅
**Target**: Complete
**Dependencies**: Milestone 1

**Features**:
- [x] Design database schema with all required tables
- [x] Create Supabase migration files
- [x] Define enums (role, status, listing_status, inquiry_status, etc.)
- [x] Implement Row Level Security (RLS) policies
- [x] Create database indexes for performance
- [x] Set up Supabase Storage buckets for listing media
- [x] Create schema documentation
- [x] Supabase CLI installed (pnpm); project linked; migrations pushed
- [x] Security: fix function search_path (migration 20260129044246)
- [x] Dev seeding: `supabase/seed.sql` (local / db reset)
- [x] DB tests: vitest + schema + RLS smoke tests (`pnpm test`)
- [x] Go-live strategy: `docs/go-live.md`

**Acceptance Criteria**:
- [x] All tables from data model are created
- [x] RLS policies enforce:
  - Pending users can only edit own profile
  - Approved users can see contact details
  - Listings require approval for visibility
  - Demographic data is admin-only
- [x] Migration files are versioned and documented
- [x] RLS policies applied via `pnpm db:push` (migrations run successfully)
- [x] DB tests exist and pass; go-live and seed policy documented

**Dependencies**:
- Requires Supabase project setup (user provides .env) ✅
- Requires org-controller guidance on RLS patterns ✅

---

### Milestone 3: Authentication & Profile Bootstrap ✅
**Target**: After Milestone 2
**Dependencies**: Milestone 2

**Features**:
- [x] Set up Supabase Auth integration
- [x] Create sign-up page (`/auth/sign-up`)
- [x] Create sign-in page (`/auth/sign-in`)
- [x] Create password reset page (`/auth/reset-password`)
- [x] Implement profile creation on first sign-up
- [x] Set up auth state management (Astro + Supabase client, cookie-based via @supabase/ssr)
- [x] Create protected route middleware

**Acceptance Criteria**:
- Users can sign up with email/password
- Users can sign in
- Users can reset passwords (request link; callback at `/auth/callback` handles recovery redirect)
- Profile record is created on sign-up with `status: 'pending'`
- Protected routes redirect unauthenticated users
- Auth state persists across page loads (cookies; middleware sets `Astro.locals.user`)

**Dependencies**:
- Requires database schema (Milestone 2)
- Requires Supabase Auth configuration

---

### Milestone 4: Onboarding Flow
**Target**: After Milestone 3
**Dependencies**: Milestone 3

**Features**:
- [ ] Create onboarding route (`/app/onboarding`)
- [ ] Build role selection (farmer vs landowner)
- [ ] Build farmer profile form (all required fields)
- [ ] Build landowner profile form (basic fields)
- [ ] Implement form validation
- [ ] Save profile data to database
- [ ] Set profile status to `pending` on completion
- [ ] Redirect to appropriate page after onboarding

**Acceptance Criteria**:
- New users are guided through onboarding
- All required profile fields are collected
- Farmer profiles include all specified fields
- Landowner profiles include basic information
- Profile status is set to `pending` after completion
- Users cannot skip onboarding
- Form validation prevents invalid submissions

**Dependencies**:
- Requires authentication (Milestone 3)
- Requires database schema (Milestone 2)

---

### Milestone 5: Admin Review Interfaces
**Target**: After Milestone 4
**Dependencies**: Milestone 4

**Features**:
- [ ] Create admin dashboard (`/admin`)
- [ ] Build user review interface (`/admin/review/users`)
- [ ] Display pending users with profile information
- [ ] Show demographic data (admin-only)
- [ ] Implement approve/reject actions
- [ ] Build listing review interface (`/admin/review/listings`)
- [ ] Display pending listings with full details
- [ ] Implement approve/reject actions for listings
- [ ] Add admin-only navigation

**Acceptance Criteria**:
- Admins can view all pending users
- Admins can see demographic data (not visible to regular users)
- Admins can approve or reject users
- User status updates correctly
- Admins can view all pending listings
- Admins can approve or reject listings
- Listing status updates correctly
- All actions are logged/auditable
- Non-admins cannot access admin routes

**Dependencies**:
- Requires user profiles (Milestone 4)
- Requires admin role assignment
- Requires RLS policies for admin access

---

### Milestone 6: Profile Management
**Target**: After Milestone 5
**Dependencies**: Milestone 5

**Features**:
- [ ] Create profile page (`/app/profile`)
- [ ] Allow users to view own profile
- [ ] Allow users to edit own profile
- [ ] Show profile status (pending/approved/rejected/suspended)
- [ ] Display appropriate messaging based on status
- [ ] Implement profile update API/route
- [ ] Validate profile edits

**Acceptance Criteria**:
- Users can view their complete profile
- Users can edit their profile (pending or approved)
- Profile status is clearly displayed
- Appropriate restrictions based on status
- Changes are saved correctly
- Form validation works

**Dependencies**:
- Requires authentication (Milestone 3)
- Requires database schema (Milestone 2)

---

### Milestone 7: Listings CRUD
**Target**: After Milestone 6
**Dependencies**: Milestone 6

**Features**:
- [ ] Create listings page (`/app/listings`)
- [ ] Build listing creation form (all required fields)
- [ ] Implement draft saving
- [ ] Build listing edit functionality
- [ ] Implement listing submission for approval
- [ ] Create listing detail page (`/app/listings/[id]`)
- [ ] Add listing media upload (photos, aerial, maps)
- [ ] Implement listing status management
- [ ] Allow landowners to archive listings

**Acceptance Criteria**:
- Approved landowners can create listings
- Listings start as `draft` status
- Landowners can save drafts
- Landowners can submit listings for approval (`pending`)
- Landowners can edit their own listings
- Listing media can be uploaded and managed
- Listing detail page shows all information
- Only approved landowners can create listings
- Listings require approval before public visibility

**Dependencies**:
- Requires approved landowner profiles (Milestone 5)
- Requires Supabase Storage setup (Milestone 2)
- Requires database schema (Milestone 2)

---

### Milestone 8: Search & Discovery
**Target**: After Milestone 7
**Dependencies**: Milestone 7

**Features**:
- [ ] Create search page (`/app/search`)
- [ ] Build listing browse interface
- [ ] Implement filtering (county, acreage, crops, etc.)
- [ ] Implement search functionality
- [ ] Display only approved listings
- [ ] Show listing cards with key information
- [ ] Link to listing detail pages
- [ ] Handle empty states

**Acceptance Criteria**:
- Approved farmers can browse approved listings
- Search and filters work correctly
- Only approved listings are visible
- Pending users cannot see listings
- Listing cards display relevant information
- Navigation to detail pages works
- Empty states are handled gracefully

**Dependencies**:
- Requires approved listings (Milestone 7)
- Requires approved farmer profiles (Milestone 5)

---

### Milestone 9: Inquiries System
**Target**: After Milestone 8
**Dependencies**: Milestone 8

**Features**:
- [ ] Create inquiry creation flow
- [ ] Build inquiries list page (`/app/inquiries`)
- [ ] Create inquiry detail page (`/app/inquiries/[id]`)
- [ ] Implement inquiry status management
- [ ] Build inquiry messaging interface (non-realtime)
- [ ] Allow farmers to send messages
- [ ] Allow landowners to respond
- [ ] Display message history
- [ ] Implement inquiry blocking (admin/landowner)

**Acceptance Criteria**:
- Approved farmers can create inquiries on approved listings
- Inquiries are created with `status: 'open'`
- Both parties can view inquiry details
- Non-realtime messaging works
- Message history is displayed
- Inquiry status can be updated
- Landowners can block inquiries
- Pending users cannot create inquiries

**Dependencies**:
- Requires approved listings (Milestone 7)
- Requires approved farmer profiles (Milestone 5)
- Requires database schema (Milestone 2)

---

### Milestone 10: Polish & QA
**Target**: Final
**Dependencies**: Milestone 9

**Features**:
- [ ] End-to-end testing of all workflows
- [ ] RLS policy validation
- [ ] UI/UX polish
- [ ] Error handling improvements
- [ ] Loading states
- [ ] Accessibility audit
- [ ] Performance optimization
- [ ] Documentation finalization

**Acceptance Criteria**:
- All user flows work end-to-end
- RLS policies are validated and tested
- No critical bugs
- UI is polished and accessible
- Performance is acceptable
- Documentation is complete

**Dependencies**:
- Requires all previous milestones

## Feature-Level Backlog Items

### High Priority (MVP Critical Path)

1. **Database Schema Design** (Milestone 2)
   - Design all tables with proper relationships
   - Define foreign keys and constraints
   - Plan indexes for performance

2. **RLS Policy Implementation** (Milestone 2)
   - Pending user restrictions
   - Approved user permissions
   - Admin-only data access
   - Listing visibility rules

3. **Auth Integration** (Milestone 3)
   - Supabase Auth setup
   - Auth state management
   - Protected routes

4. **Onboarding Forms** (Milestone 4)
   - Farmer profile form (comprehensive)
   - Landowner profile form (basic)
   - Validation and error handling

5. **Admin Approval Workflows** (Milestone 5)
   - User approval interface
   - Listing approval interface
   - Status update logic

### Medium Priority (MVP Required)

6. **Listing Management** (Milestone 7)
   - CRUD operations
   - Media upload
   - Status workflow

7. **Search & Filter** (Milestone 8)
   - Browse interface
   - Filtering logic
   - Search functionality

8. **Inquiry System** (Milestone 9)
   - Inquiry creation
   - Messaging interface
   - Status management

### Low Priority (Polish)

9. **UI/UX Enhancements** (Milestone 10)
   - Loading states
   - Error messages
   - Empty states

10. **Documentation** (Ongoing)
    - API documentation
    - RLS policy documentation
    - Deployment guide

## Dependencies & Sequencing

### Critical Path
1. Milestone 1 (Setup) → Milestone 2 (Schema) → Milestone 3 (Auth) → Milestone 4 (Onboarding) → Milestone 5 (Admin) → Milestone 6 (Profiles) → Milestone 7 (Listings) → Milestone 8 (Search) → Milestone 9 (Inquiries) → Milestone 10 (Polish)

### Parallel Work Opportunities
- Milestone 6 (Profile Management) and Milestone 7 (Listings CRUD) can be worked on in parallel after Milestone 5
- UI components can be built in parallel with backend work
- Documentation can be written incrementally

### Blocking Dependencies
- **Milestone 2 blocks everything**: Database schema must be complete before any feature work
- **Milestone 3 blocks user-facing features**: Auth must be working before onboarding
- **Milestone 5 blocks user features**: Admin approval must work before users can be approved
- **Milestone 7 blocks Milestone 8**: Listings must exist before search
- **Milestone 8 blocks Milestone 9**: Search must work before inquiries

## Notes

- All features must follow org-controller MCP guidance
- RLS policies must be validated for every feature
- Documentation must be updated as features are completed
- Each milestone should be tested before moving to the next
- Admin workflows are critical path items (users cannot proceed without approval)

## Future Considerations (Post-MVP)

- Swipe-style matching UI
- Realtime messaging
- Automated match scoring
- Mobile app
- Analytics dashboard
- Payment integration
- Advanced search algorithms
