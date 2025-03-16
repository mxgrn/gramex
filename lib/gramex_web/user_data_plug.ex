defmodule Gramex.UserDataPlug do
  @moduledoc """
  Extract user data from [update params](https://core.telegram.org/bots/api#update).
  """
  import Plug.Conn

  alias GramexWeb.Webhook

  def init(opts), do: opts

  def call(conn, _opts) do
    user_data = Webhook.extract_user_data(conn.params)
    assign(conn, :telegram_user_data, user_data)
  end
end
