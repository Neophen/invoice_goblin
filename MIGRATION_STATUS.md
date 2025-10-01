# Migration Status - Hackathon to Production

## ✅ Completed

### Finance Domain
- ✅ Finance domain module copied and updated
- ✅ All 5 Finance resources copied with multitenancy:
  - Invoice (with AI parsing, Oban triggers)
  - Statement
  - Transaction
  - CounterParty
  - InvoiceLineItem
- ✅ AI modules copied (OpenAiChatModel)
- ✅ S3Uploader utility copied
- ✅ CAMT XML parser copied
- ✅ Custom Ash types copied (InvoiceData, PartyData, LineItem)
- ✅ Migration generated (`20251001062807_add_finance_domain.exs`)
- ✅ Dependencies added (sweet_xml)
- ✅ Config updated with Finance domain

### LiveViews
- ✅ All 9 LiveView files copied:
  1. bank_statement_upload_live.ex ✅ Updated
  2. dashboard_live.ex
  3. invoice_detail_live.ex
  4. invoice_list_live.ex
  5. invoice_processing_dashboard_live.ex
  6. invoice_upload_live.ex
  7. statement_detail_live.ex
  8. statement_list_live.ex
  9. transaction_list_live.ex
- ✅ StatementFormComponent copied

## 🔄 In Progress

### LiveView Updates Needed

Each LiveView needs:
1. **Layout update**: Change `Layouts.app` → `UI.Components.Layout.app`
2. **Tenant context**: Add tenant to all Ash queries
3. **Current user access**: Get organisation from `socket.assigns.current_user`

### Pattern for adding tenant context:

```elixir
# Before:
{:ok, invoices} = Ash.read(Finance.Invoice, load: [:counter_party])

# After:
tenant = get_tenant(socket)
{:ok, invoices} = Ash.read(Finance.Invoice, load: [:counter_party], tenant: tenant)

# Helper function to add to each LiveView:
defp get_tenant(socket) do
  # Get the first organisation from the current user
  # In production, you'll want proper organisation selection
  case socket.assigns.current_user do
    %{organisations: [org | _]} -> org.id
    _ -> nil
  end
end
```

### Files requiring updates:

1. **invoice_list_live.ex** - 5 Ash.read/get calls need tenant
2. **invoice_detail_live.ex** - Multiple Ash calls need tenant
3. **invoice_upload_live.ex** - Ash.create needs tenant
4. **invoice_processing_dashboard_live.ex** - Multiple Ash calls need tenant
5. **statement_list_live.ex** - Ash.read calls need tenant
6. **statement_detail_live.ex** - Ash calls need tenant
7. **transaction_list_live.ex** - Ash.read calls need tenant
8. **dashboard_live.ex** - Multiple Ash calls need tenant
9. **StatementFormComponent** - Ash.create needs tenant

## 📋 Next Actions

1. **Run migrations**: `mix ash.migrate`
2. **Update remaining LiveViews** with:
   - Layout component references
   - Tenant context on all Ash operations
3. **Add organisation selector** to UI for users with multiple orgs
4. **Update router** to add routes for new LiveViews
5. **Test each LiveView** to ensure:
   - Tenant isolation works
   - UI renders correctly
   - All CRUD operations work

## 🎯 Production Considerations

### Multitenancy Strategy
- Users can belong to multiple organisations via `OrganisationMembership`
- Finance resources are strictly scoped (`global? false`)
- Need UI for organisation switching
- Consider adding current organisation to session/assigns

### Missing Pieces
- [ ] Organisation switcher component
- [ ] Default organisation selection logic
- [ ] Organisation creation flow
- [ ] User invitation to organisations
- [ ] Role-based permissions within organisations

### Routes to Add
```elixir
# In router.ex
live "/invoices", InvoiceListLive
live "/invoices/upload", InvoiceUploadLive
live "/invoices/:id", InvoiceDetailLive
live "/invoices/processing", InvoiceProcessingDashboardLive

live "/statements", StatementListLive
live "/statements/upload", BankStatementUploadLive
live "/statements/:id", StatementDetailLive

live "/transactions", TransactionListLive

live "/dashboard", DashboardLive
```
