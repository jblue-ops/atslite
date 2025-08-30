# Changelog

All notable changes to ATS Lite will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

---

## [0.1.0] - 2024-08-30 - Phase 1: Foundation Complete

### Added
- **Project Foundation**
  - Ruby on Rails 7.2+ application with PostgreSQL database
  - Git repository with proper branching strategy (main)
  - CLAUDE.md context file for AI-assisted development
  - CHANGELOG.md for comprehensive change tracking

- **Development Environment**
  - Docker containerization with docker-compose.yml for development
  - Production-ready Dockerfile with Kamal deployment support
  - Database initialization with PostgreSQL extensions (uuid-ossp, pg_trgm, unaccent)
  - Environment-specific configurations

- **Essential Gems & Dependencies**
  - Authentication: Devise for user management
  - Authorization: Pundit for role-based access control
  - Search: pg_search for full-text PostgreSQL search
  - State Management: state_machines-activerecord for workflow handling
  - Multi-tenancy: acts_as_tenant for company isolation
  - Background Jobs: Sidekiq for async processing
  - Activity Tracking: public_activity for audit trails
  - Rich Text: ActionText for job descriptions and notes
  - File Handling: ActiveStorage with image_processing

- **Comprehensive Testing Framework**
  - RSpec testing framework with rails_helper configuration
  - FactoryBot for test data generation with ATS-specific factories
  - Database Cleaner for test isolation
  - Shoulda Matchers for model validation testing
  - Capybara + Selenium for system/integration testing
  - VCR + WebMock for external API testing
  - SimpleCov for code coverage reporting (85% minimum threshold)
  - Custom matchers for ATS-specific functionality
  - Authentication helpers for multi-role testing

- **Code Quality & Security Tools**
  - RuboCop with Rails, Performance, RSpec, and Security extensions
  - Brakeman security scanner with ATS-specific configurations
  - Bundle Audit for dependency vulnerability scanning
  - GitHub Actions CI/CD pipeline with parallel job execution
  - Quality check scripts and Rake tasks
  - Pull request templates with security checklists

- **Frontend Infrastructure**
  - TailwindCSS for modern, responsive styling
  - Stimulus.js for JavaScript interactivity
  - Turbo for SPA-like navigation experience
  - Importmap for JavaScript module management
  - Asset pipeline optimized for development and production

### Security
- Implemented comprehensive security scanning with Brakeman
- Configured secure dependency management with Bundle Audit
- Set up proper secret management for sensitive ATS data
- Established security-focused code review processes
- Added vulnerability scanning in CI/CD pipeline

---

## Release Template

### [Version] - YYYY-MM-DD

#### Added
- New features and enhancements

#### Changed  
- Changes in existing functionality

#### Deprecated
- Soon-to-be removed features

#### Removed
- Removed features

#### Fixed
- Bug fixes

#### Security
- Security improvements and patches

---

## Development Notes

Each entry should:
- Use present tense ("Add feature" not "Added feature")
- Be user-focused (what changed for users, not internal details)
- Include issue/PR references when applicable
- Group similar changes together
- Use clear, descriptive language

Categories:
- **Added**: New features
- **Changed**: Changes in existing functionality  
- **Deprecated**: Soon-to-be removed features
- **Removed**: Now removed features
- **Fixed**: Any bug fixes
- **Security**: Security improvements