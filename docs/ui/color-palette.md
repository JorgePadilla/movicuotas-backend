## Visual Style Guide and Color Palette

### Corporate Color
**Primary Brand Color**: `#125282` (Azul Corporativo MOVICUOTAS)
- **RGB**: 18, 82, 130
- **HSL**: 207°, 76%, 29%
- **CMYK**: 86, 37, 0, 49

**Color Psychology**: The dark blue conveys:
- Trust and security - Essential for financial transactions
- Professionalism - Associated with serious financial institutions
- Stability - Communicates that the platform is solid and reliable
- Authority - Inspires respect and credibility

**Applications**:
- Main headers and navigation
- Logos and branding
- Primary action buttons
- Important titles
- Main borders and dividers

### Functional Colors

#### Status Colors

**Success / Approved - Green**: `#10b981` (RGB: 16, 185, 129)
- Credit approved
- Payment verified successfully
- Process completed
- Action confirmations
- "Active" or "Current" status badges

**Error / Rejected - Red**: `#ef4444` (RGB: 239, 68, 68)
- Credit rejected
- Customer blocked (active credit exists)
- Overdue payments / late fees
- Validation errors
- Critical error messages
- Device lock warnings

**Warning / Pending - Orange**: `#f59e0b` (RGB: 245, 158, 11)
- Payment due soon (3-5 days)
- Pending review application
- Pending verification
- Documents to complete
- Intermediate states

**Information / Neutral - Blue**: `#3b82f6` (RGB: 59, 130, 246)
- Informational messages
- Tooltips and help
- General notifications
- Secondary links
- Informational badges

#### Interface Colors

**Purple - Products and Catalog**: `#6366f1` (RGB: 99, 102, 241)
- Phone catalog
- Products section
- Device configuration
- QR codes / BluePrints

### Neutral Colors

| Color | HEX | Use |
|-------|-----|-----|
| Dark Gray | `#1f2937` | Main text, secondary headers |
| Medium Gray | `#6b7280` | Secondary text, descriptions |
| Light Gray | `#d1d5db` | Borders, separators |
| Very Light Gray | `#f3f4f6` | Secondary backgrounds, cards |
| White | `#ffffff` | Main background, featured cards |

### Typography

**Heading 1 - Main Titles**
- Font: Inter / Calibri - Bold
- Size: 28pt
- Color: `#125282`

**Heading 2 - Sections**
- Font: Inter / Calibri - Semibold
- Size: 20pt
- Color: `#1f2937`

**Body Text**
- Font: Inter / Calibri - Regular
- Size: 12pt
- Color: `#1f2937`

### Accessibility Requirements (WCAG 2.1 Level AA)

**Minimum Contrast Ratios**:
- Normal text: 4.5:1
- Large text (18pt+): 3:1
- Interactive elements: 3:1

**Approved Colors on White Background**:
- ✅ `#125282` (Corporate Blue) - Contrast 8.2:1
- ✅ `#1f2937` (Dark Gray) - Contrast 14.1:1
- ✅ `#ef4444` (Red) - Contrast 4.5:1
- ✅ `#10b981` (Green) - Contrast 3.9:1 (large text only)

### Interactive Elements

**Primary Buttons** (Active/Selected):
- Background: Status color (orange, blue, green, red, indigo)
- Text: White (`#ffffff`)
- Hover: Darker shade of status color

**Secondary Buttons** (Inactive/Unselected):
- Background: Light Gray (`#f3f4f6` or `bg-gray-100`)
- Text: Dark Gray (`#374151` or `text-gray-700`)
- Hover: Medium Gray (`#e5e7eb` or `bg-gray-200`)
- **IMPORTANT**: Never use white background with colored text for secondary buttons
- **IMPORTANT**: Always ensure sufficient contrast - white text requires dark backgrounds only

### Design Best Practices

**✅ DO**:
- Use `#125282` for brand and navigation
- Green only for confirmed success
- Red only for errors/rejections
- Maintain accessible contrast (WCAG AA)
- Use grays for text hierarchy
- Use light gray (bg-gray-100) for secondary/inactive buttons
- Use white text only on dark/colored backgrounds (600+ shades)
- Pair white text with brand blue, status colors, or very dark grays

**❌ DON'T**:
- Mix green with red in same context
- Use red for decoration
- Change the corporate blue `#125282`
- Use colors with low contrast
- Invent new status colors
- Use white backgrounds with colored text
- Use white text on light backgrounds (gray-100, gray-50, white, etc.)
- Create contrast issues that fail WCAG AA standards

### Design Philosophy

The MOVICUOTAS color palette is specifically designed for a financial credit system. Each color serves a precise psychological function:
- Generate trust in money transactions
- Clearly communicate the status of each operation
- Reduce anxiety in approval/rejection processes
- Intuitively guide the user through each step

