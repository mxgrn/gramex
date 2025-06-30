defmodule Gramex.UserDataPlug do
  @moduledoc """
  Extract user data from [update params](https://core.telegram.org/bots/api#update).
  """
  import Plug.Conn

  alias GramexWeb.Webhook

  def init(opts), do: opts

  def call(conn, _opts) do
    user_data = Webhook.extract_user_data(conn.params)

    user_data =
      Webhook.extract_message(conn.params)
      |> case do
        nil -> user_data
        message -> Map.put(user_data, "last_message", message)
      end

    assign(conn, :telegram_user_data, user_data)
  end
end
