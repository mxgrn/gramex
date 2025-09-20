defmodule Gramex.Testing.Session do
  @moduledoc """
  Note: user here is a Telegram user.
  """

  alias Gramex.Testing.BotCase.Registry
  alias Gramex.Testing.Webhook

  def new_session(user, updates \\ []) do
    Registry.add_session(user, updates)
    |> Map.get(user.id)
  end

  def send_message(%{user: user} = _session, text) do
    Webhook.post_update(
      build_update(:message,
        text: text,
        from: user,
        chat: user
      )
    )

    # return updated session
    Registry.get_session(user.id)
  end

  def click_button(%{user: user} = session, text) do
    find_update_with_button(session.updates, text)
    |> case do
      nil ->
        raise "No button with text #{text} found"

      # TODO: this should look into response instead of params, but we're not building it properly yet
      %{params: %{reply_markup: %{inline_keyboard: buttons}}} = update ->
        buttons
        |> List.flatten()
        |> Enum.find(fn %{text: button_text} -> button_text =~ text end)
        |> case do
          nil ->
            raise "No button with text #{text} found"

          %{callback_data: callback_data} ->
            Webhook.post_update(
              build_update(:callback_query,
                data: callback_data,
                from: user,
                message: update.response
              )
            )

            session
        end
    end

    Registry.get_session(user.id)
  end

  defp find_update_with_button(updates, text) do
    # for now only check the last update
    updates = [List.last(updates)]

    Enum.find(updates, fn
      # TODO: this should look into response instead of params, but we're not building it properly yet
      %{params: %{reply_markup: %{inline_keyboard: buttons}}} ->
        buttons
        |> List.flatten()
        |> Enum.any?(fn %{text: button_text} -> button_text =~ text end)

      _ ->
        false
    end)
  end

  defp build_update(:message, opts) do
    opts =
      Keyword.validate!(opts,
        from: %{},
        chat: %{},
        text: "some text",
        date: DateTime.utc_now(),
        message_id: 1
      )

    date = opts[:date] |> DateTime.to_unix()

    %{
      "message" => %{
        "chat" => opts[:chat],
        "date" => date,
        "from" => opts[:from],
        "message_id" => opts[:message_id],
        "text" => opts[:text]
      },
      "update_id" => :rand.uniform(1_000_000_000)
    }
  end

  defp build_update(:callback_query, opts) do
    opts = Keyword.validate!(opts, message: %{}, data: "", telegram_id: nil, user: %{}, from: %{})

    message = opts[:message] |> Map.put_new(:from, %{})

    %{
      # random integer
      "id" => :rand.uniform(1_000_000_000),
      "callback_query" => %{
        "data" => opts[:data] || "some_data",
        "from" => opts[:from],
        "id" => "1234567890",
        "message" => message
      }
    }
  end
end
