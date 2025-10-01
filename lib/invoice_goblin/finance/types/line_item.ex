defmodule InvoiceGoblin.Finance.Types.LineItem do
  @moduledoc """
  Typed struct for storing parsed line item data from invoices.
  """

  use Ash.TypedStruct

  typed_struct do
    field :description, :string
    field :quantity, :decimal
    field :unit_price, :decimal
    field :total, :decimal
  end
end
