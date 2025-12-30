## Core Domain Models

### Three User Types
1. **Administrators (Admin)**: Full access to all features
2. **Vendedores (Sales Staff)**: Limited to customer/loan management and sales process
3. **Cobradores (Collection Agents)**: Read-only access focused on overdue accounts and MDM device control

### Main Entities
1. **Customer**: End customer buying on credit (with date of birth for age calculation)
2. **Device**: Mobile phone with IMEI and MDM tracking
3. **Loan**: Credit agreement with contract number (format: `S01-2025-12-04-000001`)
   - **CRITICAL**: Track loan status across ALL stores/branches
   - Only ONE active loan per customer system-wide
4. **Installment**: Individual payment due dates (bi-weekly)
   - Must track status: pending, paid, overdue, cancelled
   - Each installment linked to specific loan
5. **Payment**: Actual payments made (with receipt images in S3)
   - Must track which installment(s) each payment applies to
   - Track payment history for reporting
6. **Notification**: FCM push notifications to customers
7. **CreditApplication**: Credit application requests from vendors
8. **PhoneModel**: Catalog of available phone models
9. **Contract**: Digital contracts with customer signatures
10. **MdmBlueprint**: QR codes for device MDM configuration

