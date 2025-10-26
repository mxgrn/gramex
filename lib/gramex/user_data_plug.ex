defmodule Gramex.UserDataPlug do
  @moduledoc """
  Extract user data from [update params](https://core.telegram.org/bots/api#update).
  """
  import Plug.Conn

  alias Gramex.Updates

  def init(opts), do: opts

  def call(conn, opts) do
    Updates.extract_user_data(conn.params)
    |> case do
      nil ->
        if opts[:halt_if_nil] do
          conn
          |> put_status(:ok)
          |> put_resp_content_type("application/json")
          |> send_resp(200, ~s({"halted": true}))
          |> halt()
        else
          assign(conn, :telegram_user_data, nil)
        end

      user_data ->
        user_data =
          Updates.extract_message(conn.params)
          |> case do
            nil -> user_data
            message -> Map.put(user_data, "last_message", message)
          end

        assign(conn, :telegram_user_data, user_data)
    end
  end
end
