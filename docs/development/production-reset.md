## Production Data Reset Guide

Guide for resetting production data, primarily for **customer delivery** (clean handoff) or **environment reset**.

### When to Use

- **Customer delivery**: Wipe all demo/test data, keep users + phone catalog + settings
- **Environment reset**: Start fresh after testing in production

### Prerequisites

- SSH access to the production server
- Database backup tool (`pg_dump`)
- Solid Queue workers must be stopped before reset

---

### Procedure

#### 1. Backup the Database

```bash
pg_dump $DATABASE_URL > backup_pre_reset_$(date +%Y%m%d).sql
```

#### 2. Stop Solid Queue Workers

Solid Queue stores jobs in the same PostgreSQL database. Workers **must** be stopped before truncating tables to avoid foreign key violations and orphaned job references.

```bash
# If running via systemd:
sudo systemctl stop solid_queue

# If running via Procfile/foreman:
# Stop the process manually
```

#### 3. Reset the Database

**Recommended command**: `db:seed:replant`

```bash
RAILS_ENV=production rails db:seed:replant
```

This command:
- Uses `TRUNCATE CASCADE` on all tables (respects foreign keys automatically)
- Re-runs `db/seeds.rb`
- Does **not** drop or recreate the schema (safe, no migration risk)

#### 4. Clean Orphaned S3 Files

`TRUNCATE` removes ActiveStorage records but **not** the actual files on S3. Clean them up:

```bash
RAILS_ENV=production rails runner "ActiveStorage::Blob.unattached.each(&:purge_later)"
```

#### 5. Restart Solid Queue Workers

```bash
sudo systemctl start solid_queue
```

#### 6. Verify

```bash
RAILS_ENV=production rails runner "
  puts 'Users: ' + User.count.to_s
  puts 'Phone Models: ' + PhoneModel.count.to_s
  puts 'System Settings: ' + SystemSetting.count.to_s
  puts 'Customers: ' + Customer.count.to_s
  puts 'Loans: ' + Loan.count.to_s
  puts 'Queue Jobs: ' + SolidQueue::Job.count.to_s
"
```

**Expected output for clean delivery:**
```
Users: 6
Phone Models: 10
System Settings: 1
Customers: 0
Loans: 0
Queue Jobs: 0
```

---

### What Gets Preserved vs Wiped

| Preserved (from seeds) | Wiped |
|---|---|
| Users (master, admins, supervisor, vendedor) | Customers |
| Phone model catalog (10 models) | Loans, installments, payments |
| System settings (support phone) | Credit applications |
| | Contracts, devices, MDM blueprints |
| | Notifications, audit logs |
| | Sessions, device tokens |
| | All Solid Queue job history |
| | ActiveStorage attachments |

---

### Alternative Commands

| Command | Use Case | Risk Level |
|---|---|---|
| `db:seed:replant` | Reset data, keep schema | Low |
| `db:reset` | Drop + recreate + migrate + seed | Medium (drops schema) |
| `db:migrate:reset` | Drop + recreate + all migrations + seed | Medium (re-runs all migrations) |

**Always prefer `db:seed:replant`** for production resets. The other commands drop the database entirely and are only needed if the schema itself is corrupted.

---

### Important Notes

- **Seeds are idempotent**: They use `find_or_create_by!`, safe to run multiple times
- **Passwords**: All user passwords are set in `db/seeds.rb` - review before delivery
- **S3 bucket**: Files are not deleted by database truncation, run the cleanup step
- **Recurring jobs**: Solid Queue recurring tasks will re-register automatically on worker restart
- **Demo data in seeds**: Sections 3-12 in `db/seeds.rb` create demo customers, loans, payments. For a clean delivery, these exist but `replant` + seeds will recreate them. If you want a truly blank state (no demo customers), update seeds first to remove sections 3-12
