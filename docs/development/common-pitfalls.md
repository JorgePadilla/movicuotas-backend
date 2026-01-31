## Common Pitfalls to Avoid

1. **Don't bypass authorization**: Always use `authorize` in controllers
2. **Don't put business logic in controllers**: Use services
3. **Don't forget transactions**: Loan creation, payment processing need atomicity
4. **Don't hardcode**: Use enums, constants, environment variables
5. **Don't skip audit logs**: Track locks, payments, status changes
6. **Use Turbo syntax, not Rails UJS**: This is Rails 8 with Turbo. Use `data: { turbo_method: :delete, turbo_confirm: "..." }` instead of `method: :delete, data: { confirm: "..." }`. The old UJS syntax silently fails.
7. **Add `multipart: true` to forms with file uploads**: If using raw `<input type="file">` instead of `f.file_field`, Rails won't auto-detect multipart. Without it, only the filename string is sent instead of the file binary, causing `ActiveSupport::MessageVerifier::InvalidSignature` errors.
8. **Phone catalog filtering by financed amount**: Filter phones by `price <= max_financing / (1 - min_down_payment)`, NOT by `price <= max_financing`. The limit applies to the financed amount (price - down payment), not the phone price.

