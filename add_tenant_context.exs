#!/usr/bin/env elixir

# Script to add tenant context to LiveViews

get_tenant_helper = """

  defp get_tenant(socket) do
    # Get the first organisation from the current user
    # TODO: Add proper organisation selection in production
    case socket.assigns.current_user do
      %{organisations: [%{id: org_id} | _]} -> org_id
      _ -> nil
    end
  end
"""

files_to_update = [
  "lib/invoice_goblin_web/live/invoice_upload_live.ex",
  "lib/invoice_goblin_web/live/invoice_processing_dashboard_live.ex",
  "lib/invoice_goblin_web/live/statement_detail_live.ex",
  "lib/invoice_goblin_web/live/statement_list_live.ex",
  "lib/invoice_goblin_web/live/transaction_list_live.ex"
]

Enum.each(files_to_update, fn file ->
  content = File.read!(file)

  # Skip if already has get_tenant
  unless String.contains?(content, "defp get_tenant") do
    # Add helper before final end
    updated = String.replace(content, ~r/^end\s*$/m, "#{get_tenant_helper}end", global: false)
    File.write!(file, updated)
    IO.puts("✓ Added get_tenant to #{file}")
  else
    IO.puts("- Skipped #{file} (already has get_tenant)")
  end
end)

IO.puts("\n✅ Done! Now manually add tenant: get_tenant(socket) to Ash operations")
