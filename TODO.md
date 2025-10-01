# Invoice Goblin - Hackathon to Production Migration

## Phase 1: Move Finance Domain Resources
- [ ] Copy Finance domain module
- [ ] Copy Finance.Invoice resource with AI parsing
- [ ] Copy Finance.Statement resource
- [ ] Copy Finance.Transaction resource
- [ ] Copy Finance.CounterParty resource
- [ ] Copy Finance.InvoiceLineItem resource
- [ ] Copy Finance custom types (InvoiceData, PartyData, LineItem)
- [ ] Copy AI modules (OpenAiChatModel, OpenAiEmbeddingModel)
- [ ] Copy CAMT parser module
- [ ] Copy S3Uploader utility

## Phase 2: Add Multitenancy to Finance Domain
- [ ] Add organisation_id to Finance.Invoice
- [ ] Add organisation_id to Finance.Statement
- [ ] Add organisation_id to Finance.Transaction
- [ ] Add organisation_id to Finance.CounterParty
- [ ] Add organisation_id to Finance.InvoiceLineItem
- [ ] Add multitenancy config to all Finance resources (global? false)
- [ ] Generate migration for Finance domain with multitenancy

## Phase 3: Migrate LiveViews
- [ ] Copy and update dashboard_live.ex
- [ ] Copy and update bank_statement_upload_live.ex
- [ ] Copy and update statement_detail_live.ex
- [ ] Copy and update statement_list_live.ex
- [ ] Copy and update invoice_upload_live.ex
- [ ] Copy and update invoice_detail_live.ex
- [ ] Copy and update invoice_list_live.ex
- [ ] Copy and update invoice_processing_dashboard_live.ex
- [ ] Copy and update transaction_list_live.ex

## Phase 4: Update HTML/UI Components
- [ ] Review all LiveView templates for core_components usage
- [ ] Create new UI components in lib/ui/components/ as needed
- [ ] Replace core_components with UI.* components
- [ ] Create table component if needed
- [ ] Create badge/status component if needed
- [ ] Create file upload component if needed
- [ ] Create data list component if needed

## Phase 5: Testing & Validation
- [ ] Run migrations
- [ ] Test Finance resource creation with tenant
- [ ] Test LiveView rendering
- [ ] Verify multitenancy isolation
- [ ] Check all UI components render correctly
