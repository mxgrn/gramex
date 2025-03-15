defmodule Gramex.UserDataPlug do
  @moduledoc """
  Extract user data from [update params](https://core.telegram.org/bots/api#update).
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user_data = extract_user_data(conn.params)
    assign(conn, :telegram_user_data, user_data)
  end

  defp extract_user_data(%{"message" => %{"from" => user}}), do: user
  defp extract_user_data(%{"edited_message" => %{"from" => user}}), do: user
  defp extract_user_data(%{"channel_post" => %{"from" => user}}), do: user
  defp extract_user_data(%{"edited_channel_post" => %{"from" => user}}), do: user
  defp extract_user_data(%{"business_message" => %{"from" => user}}), do: user
  defp extract_user_data(%{"edited_business_message" => %{"from" => user}}), do: user
  defp extract_user_data(%{"inline_query" => %{"from" => user}}), do: user
  defp extract_user_data(%{"callback_query" => %{"from" => user}}), do: user
  defp extract_user_data(%{"shipping_query" => %{"from" => user}}), do: user
  defp extract_user_data(%{"poll_answer" => %{"user" => user}}), do: user
  defp extract_user_data(%{"my_chat_member" => %{"from" => user}}), do: user
  defp extract_user_data(%{"chat_member" => %{"from" => user}}), do: user
  defp extract_user_data(%{"chat_join_request" => %{"from" => user}}), do: user
  defp extract_user_data(_), do: nil
end
