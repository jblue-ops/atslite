# ATS Lite - Lightweight Applicant Tracking System

A modern, lightweight Applicant Tracking System built for small businesses using Ruby on Rails.

## Features

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

## Getting Started

### Prerequisites

- Ruby 3.4.5
- PostgreSQL 14+
- Redis 7+
- Node.js 18+

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/jblue-ops/atslite.git
   cd atslite
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   rails db:create db:migrate
   ```

4. Start the development server:
   ```bash
   bin/dev
   ```

### Docker Development

```bash
docker-compose up
```

## Testing

Run the test suite:
```bash
bundle exec rspec
```

Run quality checks:
```bash
bin/quality
```

## Architecture

### Database Schema
- **Companies**: Multi-tenant root with subscription tiers
- **Users**: Role-based access (admin, recruiter, interviewer)  
- **Jobs**: Rich job postings with salary ranges and pipeline stages
- **Candidates**: GDPR-compliant profiles with skills and work authorization
- **Applications**: Pipeline management linking candidates to jobs
- **Interviews**: Comprehensive scheduling with feedback and ratings

### Key Features
- UUID primary keys for enhanced security
- JSONB fields for flexible data storage
- Full-text search with PostgreSQL trigrams
- Comprehensive database constraints
- GDPR compliance with consent management

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
