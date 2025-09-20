defmodule Gramex.Testing do
  @doc """
  Builds a Telegram callback query message.
  """
  def build_message(:callback_query, opts \\ []) do
    opts =
      Keyword.validate!(opts, data: "some:data", id: "1111111111111111", update_id: 100_000_000)

    %{
      "update_id" => opts[:update_id],
      "callback_query" => %{
        "chat_instance" => "3950670598508522825",
        "data" => opts[:data],
        "from" => %{
          "first_name" => "Max",
          "id" => 2_144_377,
          "is_bot" => false,
          "is_premium" => true,
          "language_code" => "uk",
          "last_name" => "Gorin",
          "username" => "mxgrn"
        },
        "id" => opts[:id],
        # Message that triggered the callback
        "message" => %{
          "chat" => %{
            "first_name" => "Max",
            "id" => 2_144_377,
            "last_name" => "Gorin",
            "type" => "private",
            "username" => "mxgrn"
          },
          "date" => 1_758_345_430,
          "entities" => [],
          "from" => %{
            "first_name" => "LC devbot",
            "id" => 7_581_342_610,
            "is_bot" => true,
            "username" => "lc_devbot"
          },
          "message_id" => 3399,
          "reply_markup" => %{
            "inline_keyboard" => []
          },
          "text" => "Some text"
        }
      }
    }
  end
end
