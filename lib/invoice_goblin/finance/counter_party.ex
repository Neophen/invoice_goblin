defmodule InvoiceGoblin.Finance.CounterParty do
  use Ash.Resource,
    otp_app: :invoice_goblin,
    domain: InvoiceGoblin.Finance,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "counter_parties"
    repo InvoiceGoblin.Repo
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
    global? false
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :name,
        :type,
        :email,
        :phone,
        :address,
        :registration_number,
        :tax_number,
        :website,
        :notes
      ]
    end

    update :update do
      primary? true

      accept [
        :name,
        :type,
        :email,
        :phone,
        :address,
        :registration_number,
        :tax_number,
        :website,
        :notes
      ]
    end

    create :create_from_parsed_data do
      argument :parsed_data, :map, allow_nil?: false

      change fn changeset, _context ->
        parsed_data = Ash.Changeset.get_argument(changeset, :parsed_data)

        changeset
        |> Ash.Changeset.change_attribute(:name, parsed_data["name"])
        |> Ash.Changeset.change_attribute(
          :type,
          String.to_existing_atom(parsed_data["type"] || "company")
        )
        |> Ash.Changeset.change_attribute(:email, parsed_data["email"])
        |> Ash.Changeset.change_attribute(:phone, parsed_data["phone"])
        |> Ash.Changeset.change_attribute(:address, parsed_data["address"])
        |> Ash.Changeset.change_attribute(
          :registration_number,
          parsed_data["registration_number"]
        )
        |> Ash.Changeset.change_attribute(:tax_number, parsed_data["tax_number"])
        |> Ash.Changeset.change_attribute(:website, parsed_data["website"])
      end
    end
  end

  validations do
    validate string_length(:name, max: 255)
    validate string_length(:notes, max: 1000)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
      constraints max_length: 255
    end

    attribute :type, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:company, :individual]
      default :company
    end

    attribute :email, :string do
      public? true
      constraints match: ~r/^[^\s]+@[^\s]+\.[^\s]+$/
    end

    attribute :phone, :string do
      public? true
    end

    attribute :address, :string do
      public? true
    end

    attribute :registration_number, :string do
      public? true
    end

    attribute :tax_number, :string do
      public? true
    end

    attribute :website, :string do
      public? true
    end

    attribute :notes, :string do
      public? true
    end

    attribute :organisation_id, :uuid do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    has_many :invoices, InvoiceGoblin.Finance.Invoice do
      public? true
    end

    has_many :transactions, InvoiceGoblin.Finance.Transaction do
      public? true
    end
  end
end
