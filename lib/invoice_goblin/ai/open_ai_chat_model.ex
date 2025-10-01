defmodule InvoiceGoblin.AI.OpenAiChatModel do
  @moduledoc """
  OpenAI Chat Model for invoice parsing.
  This is a simple wrapper around the OpenAI API.
  """

  def parse_invoice(file_content, file_type) do
    api_key =
      System.get_env("OPENAI_API_KEY") || raise "OPENAI_API_KEY environment variable is not set"

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    # For now, we'll only support image types
    # PDF parsing would require additional processing
    if file_type not in ["image/png", "image/jpeg", "image/jpg"] do
      {:error, "Only image files are supported for parsing currently"}
    else
      # Encode image to base64
      base64_image = Base.encode64(file_content)

      body = %{
        "model" => "gpt-4o",
        "messages" => [
          %{
            "role" => "system",
            "content" => get_system_prompt()
          },
          %{
            "role" => "user",
            "content" => [
              %{
                "type" => "text",
                "text" => "Please extract the invoice data from this image."
              },
              %{
                "type" => "image_url",
                "image_url" => %{
                  "url" => "data:#{file_type};base64,#{base64_image}",
                  "detail" => "high"
                }
              }
            ]
          }
        ],
        "temperature" => 0.1,
        "response_format" => %{"type" => "json_object"}
      }

      response =
        Req.post!("https://api.openai.com/v1/chat/completions",
          json: body,
          headers: headers,
          connect_options: [timeout: 500_000],
          receive_timeout: 500_000
        )

      case response.status do
        200 ->
          content = response.body["choices"] |> List.first() |> get_in(["message", "content"])
          {:ok, Jason.decode!(content)}

        _status ->
          {:error, response.body}
      end
    end
  end

  defp get_system_prompt do
    """
    You are an expert invoice parser. Extract the following information from the invoice:
    - Invoice number
    - Invoice date (format: YYYY-MM-DD) - this is the date the invoice was issued
    - Due date (format: YYYY-MM-DD) - this is the payment due date, which must be AFTER the invoice date
    - Total amount (as a number)
    - Currency (3-letter code like EUR, USD, etc)
    - From company/individual details (name, address, tax number, email, phone)
    - To company/individual details (name, address, tax number, email, phone)
    - Line items (description, quantity, unit price, total)
    - Tax information

    IMPORTANT: The due_date must always be later than or equal to the invoice_date. If you see dates that appear to be in the wrong order, please correct them.

    Return the data as JSON with this structure:
    {
      "invoice_number": "string",
      "invoice_date": "YYYY-MM-DD",
      "due_date": "YYYY-MM-DD",
      "total_amount": number,
      "currency": "EUR",
      "from_party": {
        "name": "string",
        "type": "company" or "individual",
        "address": "string",
        "tax_number": "string",
        "email": "string",
        "phone": "string"
      },
      "to_party": {
        "name": "string",
        "type": "company" or "individual",
        "address": "string",
        "tax_number": "string",
        "email": "string",
        "phone": "string"
      },
      "line_items": [
        {
          "description": "string",
          "quantity": number,
          "unit_price": number,
          "total": number
        }
      ],
      "tax_amount": number,
      "tax_rate": number
    }
    """
  end
end
