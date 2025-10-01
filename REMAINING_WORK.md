# Remaining Work for LiveView Migration

## ✅ Completed
- All LiveViews copied
- Layout references updated (`Layouts.app` → `Layout.app`)
- `get_tenant/1` helper added to all LiveViews needing Ash operations
- invoice_list_live.ex: ALL tenant contexts added ✅
- invoice_detail_live.ex: ALL tenant contexts added ✅

## 🔄 Need Tenant Context Added

Search each file for `Ash.read`, `Ash.get`, `Ash.create`, `Ash.update` and add `tenant: get_tenant(socket)`:

### 1. invoice_upload_live.ex
**Locations needing `tenant: tenant`:**
- Line ~19: `Ash.create(Finance.Invoice, ...)`  - Add tenant to create
- Any Ash.read calls need tenant

### 2. invoice_processing_dashboard_live.ex
**Locations needing `tenant: tenant`:**
- Line ~11: `Ash.read(Finance.Invoice, ...)` - Add tenant
- Line ~74: `Ash.update(invoice, ...)` - Should inherit from loaded resource
- Line ~84: `Ash.read(Finance.Invoice, ...)` - Add tenant

### 3. statement_detail_live.ex
**Locations needing `tenant: tenant`:**
- Line ~10: `Ash.get(Finance.Statement, id, ...)` - Add tenant
- Line ~18: `Ash.read(Finance.Transaction, ...)` - Add tenant
- Any other Ash operations

### 4. statement_list_live.ex
**Locations needing `tenant: tenant`:**
- Line ~10: `Ash.read(Finance.Statement, ...)` - Add tenant
- Any filter/search operations

### 5. transaction_list_live.ex
**Locations needing `tenant: tenant`:**
- Line ~10: `Ash.read(Finance.Transaction, ...)` - Add tenant
- Any filter operations

### 6. Statement Form Component
**File:** `lib/invoice_goblin_web/components/statement_form_component.ex`
- Needs tenant context for Ash.create operations
- May need to receive tenant as prop or get from socket

## Pattern to Follow

```elixir
# At start of function:
tenant = get_tenant(socket)

# Then in Ash operation:
Ash.read(Finance.Invoice, filter: filter, load: [:counter_party], tenant: tenant)
Ash.get(Finance.Invoice, id, load: [:counter_party], tenant: tenant)
Ash.create(Finance.Invoice, attrs, tenant: tenant)
```

## Quick Fix Command

You can search and manually update each file:
```bash
# Find all Ash operations
grep -n "Ash\\.(read\\|get\\|create\\|update)" lib/invoice_goblin_web/live/*.ex
grep -n "Ash\\.(read\\|get\\|create\\|update)" lib/invoice_goblin_web/components/*.ex
```

## After Adding Tenant Context

1. Add routes to `router.ex`:
```elixir
scope "/", InvoiceGoblinWeb do
  pipe_through [:browser, :require_authenticated_user]

  live "/dashboard", DashboardLive

  live "/invoices", InvoiceListLive
  live "/invoices/upload", InvoiceUploadLive
  live "/invoices/processing", InvoiceProcessingDashboardLive
  live "/invoices/:id", InvoiceDetailLive

  live "/statements", StatementListLive
  live "/statements/upload", BankStatementUploadLive
  live "/statements/:id", StatementDetailLive

  live "/transactions", TransactionListLive
end
```

2. Run migrations:
```bash
mix ash.migrate
```

3. Start server and test each route:
```bash
mix phx.server
```

## Testing Checklist
- [ ] Can create organisation
- [ ] Can add user to organisation
- [ ] Invoice upload works with tenant
- [ ] Invoice list shows only tenant invoices
- [ ] Statement upload works with tenant
- [ ] Transaction list scoped to tenant
- [ ] Dashboard loads correctly
- [ ] No cross-tenant data leakage
