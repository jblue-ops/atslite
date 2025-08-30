# ATS Lite Development Plan

## Project Overview
ATS Lite is a lightweight Applicant Tracking System built for small businesses using Ruby on Rails. This document tracks the development phases and current progress.

## Completed Phases ✅

### Phase 1: Initial Rails Setup ✅
**Status**: Completed  
**Branch**: `main`  
**Description**: Basic Rails application setup with PostgreSQL and TailwindCSS

- ✅ Rails 8.0.2 application initialized
- ✅ PostgreSQL database configuration
- ✅ TailwindCSS for styling
- ✅ Basic folder structure and conventions
- ✅ Git repository setup

### Phase 2.1: Database Schema & Core Models ✅
**Status**: Completed  
**Branch**: `feature/pr-2.1-database-schema-core-models`  
**Description**: Core database models and relationships

- ✅ UUID primary keys for enhanced security
- ✅ Multi-tenant architecture planning
- ✅ Database migrations for core tables
- ✅ Model associations and validations
- ✅ Factory definitions for testing

### Phase 2.2.1: Devise Authentication Setup ✅
**Status**: Completed  
**Branch**: `feature/pr-2.2.1-devise-authentication`  
**PR**: [Create PR manually](https://github.com/jblue-ops/atslite/pull/new/feature/pr-2.2.1-devise-authentication)

- ✅ Devise gem installation and configuration
- ✅ Custom User model with role-based permissions
- ✅ Organization model for multi-tenant support
- ✅ Password complexity validation
- ✅ Custom registration controller with org creation
- ✅ Professional authentication views with TailwindCSS
- ✅ Comprehensive test coverage (25 passing tests)
- ✅ Security features (lockout, session timeout)

### Phase 2.2.2: Authorization & Permissions System ✅
**Status**: Completed  
**Branch**: `feature/pr-2.2.2-authorization-permissions`  
**PR**: [Create PR manually](https://github.com/jblue-ops/atslite/pull/new/feature/pr-2.2.2-authorization-permissions)
**Description**: Comprehensive Pundit-based authorization system

- ✅ Pundit gem installation and configuration
- ✅ ApplicationPolicy with multi-tenant organization scoping
- ✅ Comprehensive UserPolicy with role-based permissions
- ✅ Policy scopes for proper data isolation between organizations
- ✅ ApplicationController authorization integration
- ✅ Comprehensive authorization test suite (22 passing tests)
- ✅ Permission-based authorization methods for granular access
- ✅ Multi-tenant security with cross-organization protection
- ✅ Role hierarchy enforcement and admin safeguards
- ✅ Production-ready code with full RuboCop compliance

**Key Features Implemented**:
- Role hierarchy: admin > hiring_manager > recruiter > interviewer > coordinator
- Organization-based data isolation in all policy scopes
- Self-management capabilities (users can edit own profiles)
- Admin-only operations with proper restrictions
- Permission-based access control system
- Comprehensive test coverage and security validation

## Current Development Phase 🚧

### Phase 3: Job Management System
**Status**: Next Up  
**Branch**: `feature/pr-3-job-management`  
**Description**: Core job posting and management functionality

**Planned Work**:
- [ ] Job model with status state machine (draft, published, closed, archived)
- [ ] Job posting form with rich text editor
- [ ] Job requirements and qualifications management
- [ ] Job template system for common roles
- [ ] Public job board views
- [ ] Job analytics and metrics
- [ ] Bulk job operations
- [ ] Authorization policies for job management
- [ ] Comprehensive test coverage for job features

## Upcoming Phases 📋

### Phase 4: Candidate Management
**Status**: Planned  
**Branch**: `feature/pr-4-candidate-management`  
**Description**: Candidate profiles and resume management

**Planned Work**:
- [ ] Candidate profile creation and editing
- [ ] Resume/CV file upload with ActiveStorage
- [ ] Parse resume data (PDF/Word extraction)
- [ ] Candidate search and filtering
- [ ] Candidate tagging and categorization
- [ ] Import candidates from CSV/LinkedIn
- [ ] Candidate communication history

### Phase 5: Application Pipeline
**Status**: Planned  
**Branch**: `feature/pr-5-application-pipeline`  
**Description**: Core ATS functionality - application tracking

**Planned Work**:
- [ ] Application model with pipeline stages
- [ ] Drag-and-drop kanban board for applications
- [ ] Application status transitions with notifications
- [ ] Application notes and comments
- [ ] Application scoring and evaluation
- [ ] Pipeline analytics and conversion metrics
- [ ] Bulk application operations

### Phase 6: Interview Scheduling
**Status**: Planned  
**Branch**: `feature/pr-6-interview-scheduling`  
**Description**: Interview management and scheduling system

**Planned Work**:
- [ ] Interview model with types (phone, video, onsite)
- [ ] Calendar integration (Google Calendar, Outlook)
- [ ] Interview scheduling with availability matching
- [ ] Interview feedback forms and evaluation
- [ ] Interview reminders and notifications
- [ ] Interview recording and note-taking
- [ ] Interview analytics and insights

### Phase 7: Communication Hub
**Status**: Planned  
**Branch**: `feature/pr-7-communication-hub`  
**Description**: Email templates and bulk communications

**Planned Work**:
- [ ] Email template system with variables
- [ ] Bulk email campaigns to candidates
- [ ] Email tracking (opens, clicks, replies)
- [ ] SMS notifications integration
- [ ] Communication history and logs
- [ ] Automated workflow triggers
- [ ] Personalized email sequences

### Phase 8: Reporting & Analytics
**Status**: Planned  
**Branch**: `feature/pr-8-reporting-analytics`  
**Description**: Comprehensive reporting and metrics

**Planned Work**:
- [ ] Dashboard with key recruiting metrics
- [ ] Pipeline conversion reports
- [ ] Time-to-hire analytics
- [ ] Source tracking and ROI analysis
- [ ] Custom report builder
- [ ] Data export functionality
- [ ] Scheduled report delivery

### Phase 9: Advanced Features
**Status**: Planned  
**Branch**: `feature/pr-9-advanced-features`  
**Description**: Premium features for enhanced functionality

**Planned Work**:
- [ ] AI-powered candidate matching
- [ ] Automated candidate screening
- [ ] Integration with job boards (Indeed, LinkedIn)
- [ ] API for third-party integrations
- [ ] Advanced search with Elasticsearch
- [ ] Mobile-responsive PWA features
- [ ] White-label customization options

### Phase 10: Production Readiness
**Status**: Planned  
**Branch**: `feature/pr-10-production-ready`  
**Description**: Deployment, monitoring, and maintenance

**Planned Work**:
- [ ] Docker containerization
- [ ] Kamal deployment configuration
- [ ] Redis caching implementation
- [ ] Background job processing with Sidekiq
- [ ] Application monitoring and logging
- [ ] Performance optimization
- [ ] Security hardening and audit
- [ ] Backup and disaster recovery

## Development Guidelines

### Git Workflow
- Create feature branches for each phase/sub-phase
- Use descriptive commit messages with conventional commits
- Create PRs for each major feature set
- Maintain clean git history with rebasing when appropriate

### Testing Strategy
- Write tests for all new functionality (models, controllers, services)
- Maintain test coverage above 90%
- Use RSpec for unit and integration tests
- Use Capybara for system/feature tests
- Use FactoryBot for test data generation

### Code Quality
- Follow Rails conventions and best practices
- Use RuboCop for code style enforcement
- Use Brakeman for security scanning
- Implement service objects for complex business logic
- Use form objects for complex multi-model forms

### Documentation
- Update this PLAN.md as phases are completed
- Maintain CLAUDE.md with project context
- Document complex business logic and decisions
- Create API documentation as features are added

## Phase Completion Checklist

For each phase, ensure:
- [ ] All planned features are implemented
- [ ] Tests are written and passing (>90% coverage)
- [ ] Code is linted and follows style guidelines
- [ ] Security scan passes (Brakeman)
- [ ] Documentation is updated
- [ ] PR is created and reviewed
- [ ] Phase is merged to main branch
- [ ] This PLAN.md is updated with completion status

## Notes

- Each phase should be completable in 1-3 development sessions
- Phases can be split into smaller PRs if they become too large
- Some phases may be developed in parallel (e.g., reporting while building core features)
- User feedback should be incorporated between phases when possible
- Performance optimization should be considered throughout development