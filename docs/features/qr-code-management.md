# QR Code Management for Contract Configuration

## Overview

The QR Code Management feature allows administrators to upload and manage QR codes for contract configurations, which are then displayed to customers on the success page after contract signing. This enables seamless device configuration through QR code scanning.

## Features

✅ **Admin Upload Interface** - Easy-to-use drag-and-drop file upload in the admin section
✅ **QR Code Storage** - Secure storage using AWS S3 via ActiveStorage
✅ **Customer Display** - QR codes displayed on the vendor success page with usage instructions
✅ **Download Capability** - Admins can download QR codes for backup or printing
✅ **Audit Logging** - Complete audit trail of who uploaded QR codes and when
✅ **Authorization** - Pundit-based role-based access control
✅ **Responsive Design** - Works seamlessly on desktop and mobile devices

## User Flows

### Admin Workflow

1. **Access Contracts Management**
   - Admin logs in and goes to Dashboard
   - Clicks "Gestión de Contratos" link
   - Sees list of all contracts with QR code status indicators

2. **Upload QR Code**
   - Clicks on a contract to view details
   - Clicks "Edit" or "Cargar Código QR" button
   - Drag-and-drop or select a PNG/JPG/GIF image
   - Clicks "Cargar Código QR" button
   - QR code is uploaded and stored
   - Admin is redirected to contract details view

3. **Manage QR Codes**
   - View list of all contracts
   - See which contracts have QR codes uploaded
   - Filter or search by contract number
   - Download QR code for backup
   - Replace QR code if needed

### Vendor Workflow

1. **Complete Contract Signing**
   - Vendor completes Step 14 (signature capture)
   - Redirected to success page (Step 15)

2. **View QR Code**
   - Success page displays QR code if uploaded
   - Shows instructions on how to use it
   - Can download contract PDF if needed

3. **Enable Device Configuration**
   - "Proceder a Configuración de Teléfono" button becomes available when:
     - QR code is uploaded by admin
     - MDM blueprint exists for device
   - Button is disabled with helpful message if QR code is missing

### Customer Workflow (Mobile App)

1. **Receive Contract**
   - Customer views contract success page
   - Sees QR code for device configuration

2. **Scan QR Code**
   - Opens device camera
   - Points to QR code displayed
   - Follows on-screen instructions
   - Device is configured with MDM

## Database Schema

### Migration: `20260101202842_add_qr_code_to_contracts`

```ruby
add_column :contracts, :qr_code_filename, :string
add_column :contracts, :qr_code_uploaded_at, :datetime
add_column :contracts, :qr_code_uploaded_by_id, :integer
add_foreign_key :contracts, :users, column: :qr_code_uploaded_by_id
```

### Contract Model

```ruby
class Contract < ApplicationRecord
  has_one_attached :qr_code
  belongs_to :qr_code_uploaded_by, class_name: 'User', optional: true

  # Methods
  def qr_code_present?
    qr_code.attached?
  end

  def upload_qr_code!(qr_code_file, uploaded_by_user)
    # Handles file attachment and audit logging
  end
end
```

## API Endpoints

### Admin Contracts

| Method | Endpoint | Description | Authorization |
|--------|----------|-------------|---|
| GET | `/admin/contracts` | List all contracts | Admin only |
| GET | `/admin/contracts/:id` | View contract details | Admin only |
| GET | `/admin/contracts/:id/edit` | QR code upload form | Admin only |
| PATCH | `/admin/contracts/:id/update_qr_code` | Upload QR code | Admin only |
| GET | `/admin/contracts/:id/download_qr_code` | Download QR code | Authenticated users |

## Implementation Details

### Controller: `Admin::ContractsController`

Located at: `app/controllers/admin/contracts_controller.rb`

**Key Methods:**
- `index` - List contracts with search and pagination
- `show` - Display contract details with QR code
- `edit` - Show QR code upload form
- `update_qr_code` - Handle file upload and storage
- `download_qr_code` - Stream QR code file for download

### Views

**Admin Views:**

1. **`admin/contracts/index.html.erb`** (Lines: 100+)
   - Responsive table showing all contracts
   - QR code status indicators (✓ Cargado / ⚠ Pendiente)
   - Search and pagination
   - Links to view and edit contracts

2. **`admin/contracts/show.html.erb`** (Lines: 220+)
   - Contract information summary
   - Customer details
   - Loan information
   - QR code preview if uploaded
   - Download and replace buttons
   - Helpful instructions for admins

3. **`admin/contracts/edit.html.erb`** (Lines: 250+)
   - Drag-and-drop file upload area
   - File validation and size limits
   - Current QR code preview (if exists)
   - Instructions for file requirements
   - JavaScript for drag-and-drop functionality

**Vendor Views:**

- **`vendor/contracts/success.html.erb`** - Updated to display QR code

## File Handling

### Supported Formats
- PNG (.png)
- JPG (.jpg, .jpeg)
- GIF (.gif)

### Size Limits
- Maximum file size: 10MB
- Recommended minimum: 200x200 pixels
- Recommended maximum: 2000x2000 pixels

### Storage
- Files stored in AWS S3 via ActiveStorage
- Filename format: `qr_code_TIMESTAMP.png`
- Metadata stored in contracts table

## Security

### Authorization (Pundit)

```ruby
class ContractPolicy < ApplicationPolicy
  def edit?
    admin?  # Only admin can edit QR codes
  end

  def update_qr_code?
    admin?  # Only admin can upload QR codes
  end

  def download_qr_code?
    show?  # Anyone with view access can download
  end
end
```

### Validation

- File type validation (images only)
- File size validation (max 10MB)
- Transaction-safe database operations
- Audit logging of all uploads

## Audit Logging

Every QR code upload is logged in the `AuditLog` table with:
- User who uploaded it
- Timestamp of upload
- Contract and loan information
- File details (filename, etc.)

```ruby
AuditLog.log(uploaded_by_user, 'qr_code_uploaded', self, {
  qr_code_filename: qr_code.filename,
  qr_code_uploaded_at: qr_code_uploaded_at,
  loan_id: loan_id
})
```

## User Interface

### QR Code Upload Form

**Features:**
- Drag-and-drop zone with visual feedback
- File selection button as fallback
- Real-time file name and size display
- Previous QR code preview (if exists)
- Helpful instructions and requirements
- Error messages with detailed feedback

**Design:**
- Responsive Tailwind CSS
- Mobile-friendly with touch support
- Accessibility compliant
- Spanish language labels

### Contract Details Page

**Displays:**
- Contract information (number, signing date, signed by)
- Customer information (name, ID, phone, email)
- Loan details (amounts, interest rate, terms)
- QR code preview (if uploaded)
  - 250x250px preview image
  - Upload timestamp
  - Uploader name
  - Download and replace buttons
- No QR code state with helpful message

### Success Page (Vendor View)

**Displays when QR code uploaded:**
- Large, clear QR code image (192x192px)
- Instructions on how to use it:
  1. Open device camera
  2. Point camera at QR code
  3. Follow on-screen instructions
  4. Confirm device configuration
  5. Device is now configured

**Displays when QR code not uploaded:**
- Warning banner with pending status
- Message explaining QR code will appear once uploaded
- Device configuration button remains disabled

## Testing

### Model Tests

```ruby
test "upload_qr_code! attaches file and sets metadata" do
  contract = create(:contract)
  qr_file = fixture_file_upload('qr_code.png', 'image/png')

  contract.upload_qr_code!(qr_file, @user)

  assert contract.qr_code.attached?
  assert_equal @user, contract.qr_code_uploaded_by
  assert contract.qr_code_uploaded_at.present?
end
```

### Controller Tests

```ruby
test "admin can upload QR code" do
  contract = create(:contract)
  sign_in @admin_user
  qr_file = fixture_file_upload('qr_code.png', 'image/png')

  patch update_qr_code_admin_contract_path(contract),
        params: { contract: { qr_code: qr_file } }

  assert_redirected_to admin_contract_path(contract)
  assert contract.reload.qr_code.attached?
end
```

## Troubleshooting

### QR Code Not Displaying

**Issue:** QR code appears as broken image on success page
**Solutions:**
1. Verify file was uploaded successfully in admin section
2. Check AWS S3 permissions and CORS settings
3. Ensure file is valid image (check file size and format)
4. Clear browser cache and refresh page

### Upload Fails

**Issue:** File upload returns error
**Solutions:**
1. Check file format (must be PNG, JPG, or GIF)
2. Verify file size is under 10MB
3. Ensure user has admin role
4. Check server logs for detailed error message

### Button Disabled on Success Page

**Issue:** "Proceder a Configuración de Teléfono" button is grayed out
**Solutions:**
1. Verify QR code is uploaded by admin
2. Verify device selection is complete
3. Verify MDM blueprint exists for device
4. Refresh page to ensure latest data is loaded

## Configuration

### Environment Variables

No additional environment variables needed. Uses existing S3 configuration from ActiveStorage setup.

### File Size Limits

To change file size limits, modify in controller:

```ruby
# In admin/contracts_controller.rb
MAX_FILE_SIZE = 10.megabytes
```

### Supported Formats

To add or remove image formats, modify in form validation:

```ruby
# In edit view
accept: "image/*"  # Accepts all image types
```

## Performance Considerations

- QR codes are stored in S3, not database
- Database stores only filename and metadata
- Image delivery uses CDN for fast load times
- Pagination in contracts list prevents loading too many records
- Search uses indexed database columns

## Browser Compatibility

- Chrome/Edge: Full support
- Firefox: Full support
- Safari: Full support
- Mobile Safari: Full support with drag-and-drop
- IE11: Basic support (no drag-and-drop)

## Future Enhancements

1. **QR Code Generation**
   - Auto-generate QR codes from contract data
   - Allow customization of QR code appearance
   - Add branding/logo to QR codes

2. **Analytics**
   - Track QR code scans from mobile app
   - Generate reports on device configuration success rates

3. **Batch Operations**
   - Upload QR codes for multiple contracts at once
   - Generate QR codes in bulk

4. **Notifications**
   - Email vendors when QR code is uploaded
   - Notify customers when device configuration is complete

5. **Integration**
   - Add QR code to printed contracts
   - Include in email confirmations

## Support

For issues or feature requests, contact the development team or create an issue in the repository.

---

**Last Updated:** 2026-01-01
**Version:** 1.0
**Status:** Production Ready
