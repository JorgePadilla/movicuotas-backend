## Vendor Workflow Implementation Notes

### Controllers Structure
- `Vendor::SessionsController` - Step 1: Login
- `Vendor::CustomerSearchController` - Step 2: Main screen - Search customer across all stores
- `Vendor::CreditApplicationsController` - Steps 4-7: Application submission
- `Vendor::DeviceSelectionsController` - Step 10: Phone model selection
- `Vendor::PaymentCalculatorsController` - Step 12: Calculate bi-weekly payments
- `Vendor::ContractsController` - Steps 13-14: Contract generation and signature
- `Vendor::LoansController` - Step 15: Finalize loan creation
- `Vendor::MdmBlueprintsController` - Step 16: QR code display
- `Vendor::DeviceConfigurationsController` - Step 17: Final checklist
- `Vendor::DashboardController` - Dashboard (accessible from menu)

### Key Services for Vendor Workflow
- `CreditApprovalService` - Evaluate application and determine approval
- `ContractGeneratorService` - Generate PDF contracts with customer data
- `BiweeklyCalculatorService` - Calculate bi-weekly installment payments
- `LoanFinalizationService` - Complete loan creation with all dependencies

### Important Validations
1. **Active Loan Check (CRITICAL - Step 2)**:
   - Query: `Customer.joins(:loans).where(loans: { status: 'active' })`
   - **Must check across ALL stores/branches in entire system**
   - Block new credit if ANY active loan exists
   - This is the MAIN SCREEN after login
2. **IMEI Uniqueness**: Validate IMEI not in `devices` table
3. **Price Validation**: `phone_price <= approved_amount` (phone only, no accessories)
4. **Bi-weekly Calculation**: Use proper interest rate division (annual_rate / 26 for bi-weekly)
5. **Age Validation**: Calculate from date_of_birth, must meet minimum age requirement
6. **Payment Tracking**: Each payment must link to installment(s) and update loan balance

