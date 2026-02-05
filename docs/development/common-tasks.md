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

### Production Data Reset
```bash
# See full guide: docs/development/production-reset.md
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d).sql  # 1. Backup
sudo systemctl stop solid_queue                       # 2. Stop workers
RAILS_ENV=production rails db:seed:replant            # 3. Truncate + re-seed
RAILS_ENV=production rails runner \
  "ActiveStorage::Blob.unattached.each(&:purge_later)" # 4. Clean S3
sudo systemctl start solid_queue                       # 5. Restart workers
```

