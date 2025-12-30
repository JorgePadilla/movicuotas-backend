## Common Tasks & Commands

### Setup
```bash
bin/setup                    # Initial setup
bin/rails db:create db:migrate db:seed
```

### Development
```bash
bin/dev                      # Start server + jobs
bin/rails c                  # Console
bin/rails routes | grep api  # View API routes
bin/rails routes | grep vendor  # View vendor routes
```

### Testing
```bash
bin/rails test               # Run all tests
bin/rails test test/models
bin/rails test test/services
bin/rails test test/controllers/vendor
```

### Database
```bash
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:reset           # Drop, create, migrate, seed
```

