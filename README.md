# Illinois Farmlink App (MVP)

## Project Purpose

The Illinois Farmlink App is a web application that connects farmers with landowners through profiles, listings, and an approval-based matching workflow. The platform facilitates farmland access by enabling farmers to discover available properties and landowners to find suitable farming partners, with all interactions moderated through an admin approval system.

## High-Level Architecture

The application follows a server-side rendered architecture with client-side interactivity where needed:

- **Frontend**: Astro framework with Tailwind CSS for styling and React islands for interactive components
- **Backend**: Supabase (PostgreSQL database, Authentication, Storage, Row Level Security)
- **Server Logic**: Astro SSR routes and Supabase Edge Functions
- **Security**: Row Level Security (RLS) policies enforce all data access rules at the database level

### Key Architectural Principles

- **Approval-Driven Workflow**: All users and listings require admin approval before full visibility
- **Role-Based Access Control**: Enforced via Supabase RLS, not UI-only logic
- **Status-Based Permissions**: Users progress through statuses (pending → approved → rejected/suspended)
- **Future-Ready Design**: Architecture supports future features (swipe-style matching, realtime messaging) without implementing them in MVP

## Tech Stack

### Frontend
- **Framework**: [Astro](https://astro.build/) - Server-side rendering with component islands
- **Styling**: [Tailwind CSS](https://tailwindcss.com/) - Utility-first CSS framework
- **Interactivity**: React islands (only where needed for dynamic UI)

### Backend & Infrastructure
- **Database**: Supabase PostgreSQL
- **Authentication**: Supabase Auth (custom UI, no custom auth implementation)
- **Storage**: Supabase Storage (for listing media)
- **Security**: Supabase Row Level Security (RLS) for all data access control
- **Server Functions**: Astro SSR routes and Supabase Edge Functions

### Development Tools
- **Package Manager**: pnpm (required)
- **Supabase CLI**: Installed via pnpm (`pnpm add -D supabase`). Use `pnpm supabase`, `pnpm db:link`, `pnpm db:push`.
- **Type Checking**: TypeScript
- **Linting**: ESLint (configured per project standards)

## Environment Setup

### Prerequisites
- Node.js 18+ and pnpm
- Supabase account and project
- Git

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd farmlinkmatcher
   ```

2. **Install dependencies**
   ```bash
   pnpm install
   ```

3. **Set up Supabase**
   - Create a new Supabase project at https://supabase.com
   - Add a `.env` file with at least: `project_id`, `project_url`, `anon_public_key` (see `.env.example` for optional `PUBLIC_*` names the app uses)
   - Log in to the Supabase CLI once: `pnpm supabase login`
   - Link this repo to your project: `pnpm db:link` (uses `project_id` from `.env`)
   - Apply migrations: `pnpm db:push`

4. **Configure environment variables**
   Copy `.env.example` to `.env` and set your Supabase values. The app expects:
   - `PUBLIC_SUPABASE_URL` — use your project URL (e.g. same as `project_url` in `.env`)
   - `PUBLIC_SUPABASE_ANON_KEY` — use your anon key (e.g. same as `anon_public_key`)
   - `SUPABASE_SERVICE_ROLE_KEY` — optional, for server-side admin operations
   Do not commit `.env` (it is in `.gitignore`).

5. **Start development server**
   ```bash
   pnpm dev
   ```

6. **Build for production**
   ```bash
   pnpm build
   ```

## Approval Workflow Overview

The application uses a multi-stage approval process:

### User Approval Flow

1. **Registration**: User signs up and selects role (farmer or landowner)
2. **Onboarding**: User completes profile with required information
3. **Pending Status**: User profile is created with `status: 'pending'`
4. **Admin Review**: Admin reviews profile in `/admin/review/users`
5. **Approval Decision**: Admin approves or rejects
   - **Approved**: User gains full access (view listings, create inquiries)
   - **Rejected**: User is notified and cannot proceed
   - **Suspended**: Admin can suspend approved users

### Listing Approval Flow

1. **Creation**: Approved landowner creates a listing (starts as `status: 'draft'`)
2. **Submission**: Landowner submits listing for review (`status: 'pending'`)
3. **Admin Review**: Admin reviews listing in `/admin/review/listings`
4. **Approval Decision**: Admin approves or rejects
   - **Approved**: Listing becomes publicly visible to approved farmers
   - **Rejected**: Listing remains hidden, landowner notified
   - **Archived**: Admin or landowner can archive approved listings

### Inquiry Flow

1. **Expression of Interest**: Approved farmer creates inquiry on approved listing
2. **Status Tracking**: Inquiry status (open, closed, blocked)
3. **Messaging**: Non-realtime messages between farmer and landowner (MVP)

## Role/Status Model

### Roles

The application supports three roles:

- **`farmer`**: Users seeking farmland access
- **`landowner`**: Users offering farmland
- **`admin`**: Platform administrators with moderation capabilities

### Status Values

All users and listings have a status field that controls visibility and permissions:

- **`pending`**: Awaiting admin approval (limited access)
- **`approved`**: Active and fully functional
- **`rejected`**: Denied access (cannot proceed)
- **`suspended`**: Temporarily disabled (admin action)

### Status-Based Permissions

#### Pending Users
- ✅ Can edit own profile
- ❌ Cannot see contact details of other users
- ❌ Cannot create inquiries
- ❌ Cannot see full listing details

#### Approved Users
- ✅ Full profile visibility (own and others' contact info)
- ✅ Can create and manage listings (landowners)
- ✅ Can view all approved listings
- ✅ Can create inquiries on approved listings
- ✅ Can send/receive inquiry messages

#### Admin Users
- ✅ Access to admin dashboard
- ✅ Can review and approve/reject users and listings
- ✅ Can view demographic data (admin-only fields)
- ✅ Can suspend users
- ✅ Can archive listings

### Important Notes

- "Pending farmer" is a **status**, not a role. A user with `role: 'farmer'` and `status: 'pending'` is a pending farmer.
- All permission enforcement is done via Supabase RLS policies, not UI-only checks.
- Demographic data (gender, age_range, veteran_status, race, ethnicity, disability_status) is **admin-only** and never exposed to regular users or used for matching.

## Data Model Overview

### Core Tables

- **`profiles`**: Base user record (linked to `auth.users`)
- **`farmer_profiles`**: Extended farmer-specific information
- **`landowner_profiles`**: Extended landowner-specific information
- **`listings`**: Farmland/opportunity listings
- **`listing_media`**: Photos, aerial images, maps for listings
- **`inquiries`**: Farmer expressions of interest in listings
- **`inquiry_messages`**: Messages within inquiries (non-realtime in MVP)

See database schema documentation (to be created) for full table structures and relationships.

## Routing Structure

### Public Routes
- `/` - Landing page
- `/about` - About page

### Authentication Routes
- `/auth/sign-up` - User registration
- `/auth/sign-in` - User login
- `/auth/reset-password` - Password reset

### Application Routes (Protected)
- `/app` - Dashboard/home
- `/app/onboarding` - Profile completion flow
- `/app/profile` - User profile management
- `/app/listings` - Browse listings
- `/app/listings/[id]` - Listing detail page
- `/app/search` - Search/filter listings
- `/app/inquiries` - User's inquiries
- `/app/inquiries/[id]` - Inquiry detail and messaging

### Admin Routes (Admin Only)
- `/admin` - Admin dashboard
- `/admin/review/users` - User approval interface
- `/admin/review/listings` - Listing approval interface

## Security & Privacy

- **Row Level Security (RLS)**: All data access is enforced at the database level
- **Demographic Data**: Admin-only, never exposed to users, never used for matching
- **Contact Information**: Only visible to approved users
- **Pending Users**: Cannot see contact details or create inquiries
- **Admin Actions**: All admin actions are logged and auditable

## Development Guidelines

### Definition of Done

A feature is not done unless:
- ✅ org-controller MCP guidance was consulted
- ✅ RLS rules are validated and tested
- ✅ README or docs updated if needed
- ✅ Backlog item updated/closed
- ✅ Admin vs approved vs pending access verified
- ✅ Tests pass
- ✅ Lint/format checks pass

### Code Standards

- Follow org-controller MCP guidance for architecture and security patterns
- All database access must respect RLS policies
- Use TypeScript for type safety
- Write tests for critical paths
- Document complex logic and RLS policies

## Non-Goals (MVP)

The following features are explicitly **not** part of the MVP:

- ❌ Swipe-style matching UI
- ❌ Realtime chat/messaging
- ❌ Automated match scoring algorithms
- ❌ Payments or monetization features
- ❌ Analytics dashboards
- ❌ Mobile apps (web-only for MVP)

These may be considered for future releases.

## Contributing

See `BACKLOG.md` for current development priorities and milestones.

## License

[To be determined]
