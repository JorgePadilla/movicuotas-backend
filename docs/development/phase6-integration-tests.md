# Phase 6: Integration Tests

## Overview

Phase 6 focuses on implementing comprehensive integration tests for all three user role workflows:
- **Admin**: Dashboard, user management, loan management, payments, reports
- **Supervisor (Cobrador)**: Overdue tracking, device blocking, collection reports
- **Vendedor (Seller)**: 18-screen credit application workflow

## Test Infrastructure

- **Framework**: Minitest (Rails default)
- **Browser Tests**: Capybara with Selenium WebDriver
- **Test Location**: `test/integration/` and `test/system/`

## Bugs Found by Integration Tests

The following bugs were discovered during integration testing and need to be fixed:

### 1. `group_values_as_hash` Method Not Found
- **File**: `app/controllers/supervisor/collection_reports_controller.rb:57`
- **Error**: `NoMethodError: undefined method 'group_values_as_hash'`
- **Cause**: This method doesn't exist in Rails 8 ActiveRecord
- **Fix**: Replace with proper ActiveRecord group/count methods

### 2. Missing JOIN on Customers Table
- **File**: `app/controllers/supervisor/bulk_operations_controller.rb:8`
- **Error**: `PG::UndefinedTable: ERROR: missing FROM-clause entry for table "customers"`
- **Cause**: Query references `customers` table without joining it
- **Fix**: Add `.joins(:customer)` or proper association

### 3. Raw SQL Not Wrapped in Arel.sql()
- **File**: `app/controllers/supervisor/overdue_devices_controller.rb:143`
- **Error**: `ActiveRecord::UnknownAttributeReference: Dangerous query method`
- **Cause**: Rails 8 requires raw SQL to be wrapped in `Arel.sql()`
- **Fix**: Wrap the ORDER BY clause in `Arel.sql()`

### 4. Wrong Route Helper Name
- **File**: `app/views/supervisor/overdue_devices/block_confirmation.html.erb:95`
- **Error**: `undefined method 'supervisor_overdue_device_confirm_block_path'`
- **Cause**: Route helper name doesn't match the defined route
- **Fix**: Use correct route helper `confirm_block_supervisor_overdue_device_path`

### 5. Missing Spanish Translation
- **File**: `app/views/supervisor/overdue_devices/show.html.erb:128`
- **Error**: `Translation missing: es.date.formats.short`
- **Cause**: Spanish locale file missing date format
- **Fix**: Add translation to `config/locales/es.yml`

### 6. Policy Issue - Supervisor Access to Vendor Dashboard
- **Test**: `supervisor_cannot_create_loans`
- **Expected**: Redirect (403)
- **Actual**: 200 OK
- **Cause**: Policy may be too permissive for supervisors
- **Fix**: Review and tighten VendorPolicy

## Test Files

| File | Description |
|------|-------------|
| `test/integration/admin_workflow_test.rb` | Admin dashboard, users, customers, loans, payments, reports |
| `test/integration/supervisor_workflow_test.rb` | Overdue devices, blocking, payment history, collection reports |
| `test/integration/vendedor_workflow_test.rb` | 18-screen credit application workflow |
| `test/integration_test_helper.rb` | Shared test helpers for integration tests |
| `test/application_system_test_case.rb` | Base class for Capybara system tests |

## Running Tests

```bash
# Run all integration tests
bin/rails test test/integration/

# Run specific test file
bin/rails test test/integration/admin_workflow_test.rb

# Run specific test
bin/rails test test/integration/admin_workflow_test.rb:25
```

## Status

- [x] Test infrastructure setup
- [x] Admin workflow tests created
- [x] Supervisor workflow tests created
- [x] Vendedor workflow tests created
- [ ] Fix bugs discovered by tests
- [ ] All tests passing
