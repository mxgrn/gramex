defmodule GramexWeb.Webhook do
  @moduledoc """
  Extract user data from [update params](https://core.telegram.org/bots/api#update).
  """

  def extract_user_data(%{} = update) do
    update
    |> Map.drop(["update_id"])
    # take the single remaining {key, value}
    |> Enum.at(0)
    |> case do
      {_type, obj} when is_map(obj) -> obj["from"] || obj["user"]
      _ -> nil
    end
  end

  @doc """
  Extracts the message text from the update params.
  """
  def extract_message(%{"message" => %{"text" => text}}), do: text
  def extract_message(%{"edited_message" => %{"text" => text}}), do: text
  def extract_message(_), do: nil
end
