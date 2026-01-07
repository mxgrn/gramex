defmodule Gramex.Updates do
  @moduledoc """
  Functions to extract data from Telegram bot updates.
  """

  require Logger

  @doc """
  Returns a list of all possible update types as per [Telegram Bot API](https://core.telegram.org/bots/api#update).
  """
  def update_types do
    [
      "message",
      "edited_message",
      "channel_post",
      "edited_channel_post",
      "business_connection",
      "business_message",
      "edited_business_message",
      "deleted_business_messages",
      "message_reaction",
      "message_reaction_count",
      "inline_query",
      "chosen_inline_result",
      "callback_query",
      "shipping_query",
      "pre_checkout_query",
      "purchased_paid_media",
      "poll",
      "poll_answer",
      "my_chat_member",
      "chat_member",
      "chat_join_request",
      "chat_boost",
      "removed_chat_boost"
    ]
  end

  @doc """
  Extracts user data from [update params](https://core.telegram.org/bots/api#update).
  """
  def extract_user_data(%{"from" => data}), do: data
  def extract_user_data(%{"user" => data}), do: data

  def extract_user_data(%{"update_id" => _} = update) do
    update
    |> extract_payload()
    |> extract_user_data()
    |> enhance_user_data_with_gramex_fields(update)
  end

  def extract_user_data(_), do: nil

  @doc """
  Extracts chat data from [update params](https://core.telegram.org/bots/api#update) or any type of update such as Message or CallbackQuery.
  """
  def extract_chat_data(%{"chat" => chat}), do: chat

  def extract_chat_data(%{"update_id" => _} = update) do
    update
    |> extract_payload()
    |> extract_chat_data()
  end

  def extract_chat_data(_), do: nil

  @doc """
  Extracts the message text from the update params.
  """
  def extract_message(%{"message" => %{"text" => text}}), do: text
  def extract_message(%{"edited_message" => %{"text" => text}}), do: text
  def extract_message(_), do: nil

  def enhance_user_data_with_gramex_fields(nil, _), do: nil

  def enhance_user_data_with_gramex_fields(data, update) do
    cond do
      blocking_bot_update?(update) ->
        Map.put(data, "gramex_bot_blocked_at", DateTime.utc_now() |> DateTime.to_iso8601())

      unblocking_bot_update?(update) ->
        Map.put(data, "gramex_bot_blocked_at", nil)

      true ->
        data
    end
  end

  @doc """
  Extracts the payload from the update params, e.g. the value of the "message" key for message updates.
  """
  def extract_payload(update) do
    type = Enum.find(update_types(), &Map.has_key?(update, &1))
    Map.get(update, type)
  end

  defp blocking_bot_update?(%{
         "my_chat_member" => %{"new_chat_member" => %{"status" => "kicked"}}
       }), do: true

  defp blocking_bot_update?(_), do: false

  defp unblocking_bot_update?(%{
         "my_chat_member" => %{"new_chat_member" => %{"status" => "member"}}
       }), do: true

  defp unblocking_bot_update?(_), do: false
end
