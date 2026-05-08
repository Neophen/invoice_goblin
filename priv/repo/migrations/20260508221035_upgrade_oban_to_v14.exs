defmodule InvoiceGoblin.Repo.Migrations.UpgradeObanToV14 do
  use Ecto.Migration

  def up, do: Oban.Migrations.up()

  def down, do: Oban.Migrations.down(version: 13)
end
