defmodule Gramex.Updates do
  @moduledoc """
  Functions to extract data from Telegram bot updates.
  """

  require Logger

  @doc """
  Extracts user data from [update params](https://core.telegram.org/bots/api#update).
  """
  def extract_user_data(%{"from" => data}), do: data
  def extract_user_data(%{"user" => data}), do: data

  def extract_user_data(%{"update_id" => _} = update) do
    update
    |> Map.delete("update_id")
    # take the single remaining {key, value}
    |> Enum.at(0)
    |> elem(1)
    |> extract_user_data()
    |> then(fn data ->
      if blocking_bot_update?(update) do
        data
        |> Map.put("gramex_bot_blocked_at", DateTime.utc_now() |> DateTime.to_iso8601())
      else
        data
      end
    end)
    |> then(fn data ->
      if unblocking_bot_update?(update) do
        data
        |> Map.put("gramex_bot_blocked_at", nil)
      else
        data
      end
    end)
  end

  def extract_user_data(_), do: nil

  @doc """
  Extracts chat data from [update params](https://core.telegram.org/bots/api#update) or any type of update such as Message or CallbackQuery.
  """
  def extract_chat_data(%{"chat" => chat}), do: chat

  def extract_chat_data(%{"update_id" => _} = update) do
    update
    |> Map.delete("update_id")
    # take the single remaining {key, value}
    |> Enum.at(0)
    |> elem(1)
    |> extract_chat_data()
  end

  def extract_chat_data(_), do: nil

  @doc """
  Extracts the message text from the update params.
  """
  def extract_message(%{"message" => %{"text" => text}}), do: text
  def extract_message(%{"edited_message" => %{"text" => text}}), do: text
  def extract_message(_), do: nil

  defp blocking_bot_update?(%{
         "my_chat_member" => %{"new_chat_member" => %{"status" => "kicked"}}
       }), do: true

  defp blocking_bot_update?(_), do: false

  defp unblocking_bot_update?(%{
         "my_chat_member" => %{"new_chat_member" => %{"status" => "member"}}
       }), do: true

  defp unblocking_bot_update?(_), do: false
end
