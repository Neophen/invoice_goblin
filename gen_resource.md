mix ash.gen.resource InvoiceGoblin.Finance.BankAccount \
  --default-actions read \
  --uuid-primary-key uuidv7 \
  --attribute subject:string:required:public \
  --relationship belongs_to:organisation:InvoiceGoblin.Accounts.Organisation \
  --timestamps \
  --extend postgres
