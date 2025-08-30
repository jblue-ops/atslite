# ATS Lite - Context for Claude Code

## Project Overview
ATS Lite is a lightweight Applicant Tracking System built for small businesses using Ruby on Rails. It provides essential recruiting features without the complexity of enterprise-level solutions.

## Key Features
- **Job Management**: Create, publish, and manage job postings
- **Candidate Pipeline**: Track candidates through hiring stages (Applied → Screening → Interview → Offer → Hired/Rejected)
- **Interview Scheduling**: Calendar integration and automated scheduling
- **Daily Recruiting Briefs**: Automated summaries and metrics
- **Communication Hub**: Email templates and bulk communications
- **Multi-tenant**: Support for multiple companies

## Tech Stack
- **Backend**: Ruby on Rails 7.2+
- **Database**: PostgreSQL with Redis for caching
- **Frontend**: Stimulus.js + Turbo for SPA-like experience
- **Styling**: TailwindCSS
- **Authentication**: Devise with role-based access
- **Background Jobs**: Sidekiq
- **Testing**: RSpec, FactoryBot, Faker
- **Deployment**: Docker + Kamal

## Architecture Decisions

### Models & Database
- Multi-tenant architecture using Company model
- State machines for job and application status
- Polymorphic associations for interviews
- Full-text search with pg_search
- File uploads with ActiveStorage

### Controllers & Services
- Skinny controllers, business logic in service objects
- Pundit for authorization policies
- Form objects for complex multi-model forms
- Query objects for complex database operations

### Frontend
- Server-side rendering with Turbo/Stimulus
- ViewComponent for reusable UI components
- Real-time updates with ActionCable
- Progressive Web App capabilities

## Development Workflow
1. Create feature branches from `main`
2. Use TDD with RSpec
3. Follow Rails conventions and best practices
4. Run Rubocop for code style
5. Use Brakeman for security scanning
6. Create PRs with comprehensive descriptions

## Database Schema

### Core Models
- **User**: Authentication with roles (admin, recruiter, interviewer)
- **Company**: Tenant isolation
- **Job**: Job postings with requirements and status
- **Candidate**: Applicant profiles with resumes
- **Application**: Links candidates to jobs with pipeline status
- **Interview**: Scheduling and feedback
- **Activity**: Audit trail for all actions
- **EmailTemplate**: Customizable communication templates

### Key Associations
```ruby
Company has_many :users, :jobs, :candidates, :applications
Job belongs_to :company, has_many :applications
Candidate belongs_to :company, has_many :applications
Application belongs_to :job, :candidate, has_many :interviews
```

## Commands to Remember
- `rails server` - Start development server
- `rails console` - Interactive console
- `rails generate` - Code generators
- `bundle exec rspec` - Run tests
- `rubocop -a` - Auto-fix style issues
- `brakeman` - Security scan

## Useful Rails Generators
- `rails g model ModelName field:type`
- `rails g controller ControllerName action`
- `rails g migration AddFieldToModel field:type`
- `rails g service ServiceName`
- `rails g component ComponentName`

## Testing Strategy
- Unit tests for models and services
- Controller tests for API endpoints
- System tests for user workflows
- Factory patterns for test data
- Feature specs with Capybara

## Performance Considerations
- Database indexing for search fields
- N+1 query prevention with includes/joins
- Background job processing with Sidekiq
- Caching with Redis
- CDN for assets

## Security Measures
- Pundit authorization policies
- Strong parameters in controllers
- CSRF protection enabled
- Secure headers configured
- Regular Brakeman security scans
- Database constraints and validations

## Deployment Notes
- Docker containerization for consistent environments
- Kamal for zero-downtime deployments
- Environment-based configuration
- Database backups and monitoring
- SSL/TLS termination

This context file helps maintain consistency and provides quick reference for development decisions and conventions used throughout the project.