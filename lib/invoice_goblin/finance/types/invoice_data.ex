defmodule InvoiceGoblin.Finance.Types.InvoiceData do
  @moduledoc """
  Typed struct for storing complete parsed invoice data.
  """

  use Ash.TypedStruct

  typed_struct do
    field :invoice_number, :string
    field :invoice_date, :date
    field :due_date, :date
    field :total_amount, :decimal
    field :currency, :string
    field :from_party, InvoiceGoblin.Finance.Types.PartyData
    field :to_party, InvoiceGoblin.Finance.Types.PartyData
    field :line_items, {:array, InvoiceGoblin.Finance.Types.LineItem}
    field :tax_amount, :decimal
    field :tax_rate, :decimal
    field :notes, :string
  end
end
