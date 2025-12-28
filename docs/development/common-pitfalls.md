## Common Pitfalls to Avoid

1. **Don't bypass authorization**: Always use `authorize` in controllers
2. **Don't put business logic in controllers**: Use services
3. **Don't forget transactions**: Loan creation, payment processing need atomicity
4. **Don't hardcode**: Use enums, constants, environment variables
5. **Don't skip audit logs**: Track locks, payments, status changes

