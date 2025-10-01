defmodule InvoiceGoblin.Finance.Types.PartyData do
  @moduledoc """
  Typed struct for storing parsed party (company/individual) data from invoices.
  """

  use Ash.TypedStruct

  typed_struct do
    field :name, :string
    # :company or :individual
    field :type, :atom
    field :address, :string
    field :tax_number, :string
    field :registration_number, :string
    field :email, :string
    field :phone, :string
    field :website, :string
  end
end
