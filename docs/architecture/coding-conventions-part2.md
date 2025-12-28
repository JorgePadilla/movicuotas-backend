## Coding Conventions

### Models
- Use enums for status fields
- Add database indexes for foreign keys and frequently queried fields
- Validate presence and uniqueness where appropriate
- Use scopes for common queries

### Controllers
- Keep actions thin, delegate to services
- Always authorize with Pundit
- Use strong parameters
- Return proper HTTP status codes

### Services
- One public method per service
- Use `ActiveRecord::Base.transaction` for multi-step operations
- Raise custom errors for business logic failures
- Return meaningful objects, not booleans

### Components
- Keep components focused and reusable
- Pass data via initializer, not instance variables
- Use slots for flexible content areas
- **Always use the defined color palette** - Never hardcode arbitrary colors
- Use Tailwind CSS color utilities that match the brand palette
- Example: `bg-[#125282]` for corporate blue, `text-green-600` for success states

### Jobs
- Set appropriate queue priorities
- Use `retry_on` for transient failures
- Keep jobs idempotent

