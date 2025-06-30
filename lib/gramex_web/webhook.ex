defmodule GramexWeb.Webhook do
  @moduledoc """
  Extract user data from [update params](https://core.telegram.org/bots/api#update).
  """

  def extract_user_data(%{"message" => %{"from" => user}}), do: user
  def extract_user_data(%{"edited_message" => %{"from" => user}}), do: user
  def extract_user_data(%{"channel_post" => %{"from" => user}}), do: user
  def extract_user_data(%{"edited_channel_post" => %{"from" => user}}), do: user
  def extract_user_data(%{"business_message" => %{"from" => user}}), do: user
  def extract_user_data(%{"edited_business_message" => %{"from" => user}}), do: user
  def extract_user_data(%{"inline_query" => %{"from" => user}}), do: user
  def extract_user_data(%{"callback_query" => %{"from" => user}}), do: user
  def extract_user_data(%{"shipping_query" => %{"from" => user}}), do: user
  def extract_user_data(%{"poll_answer" => %{"user" => user}}), do: user
  def extract_user_data(%{"my_chat_member" => %{"from" => user}}), do: user
  def extract_user_data(%{"chat_member" => %{"from" => user}}), do: user
  def extract_user_data(%{"chat_join_request" => %{"from" => user}}), do: user
  def extract_user_data(_), do: nil

  @doc """
  Extracts the message text from the update params.
  """
  def extract_message(%{"message" => %{"text" => text}}), do: text
  def extract_message(%{"edited_message" => %{"text" => text}}), do: text
  def extract_message(_), do: nil
end
