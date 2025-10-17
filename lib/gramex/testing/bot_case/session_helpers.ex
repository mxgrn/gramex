defmodule Gramex.Testing.BotCase.SessionHelpers do
  @moduledoc """
  Helpers that get imported when `using` `Gramex.Testing.BotCase`.
  """

  alias Gramex.Testing.Sessions.Chat
  alias Gramex.Testing.Sessions.Registry
  alias Gramex.Testing.Sessions.Update
  alias Gramex.Testing.Sessions.User
  alias Gramex.Testing.Webhook

  def start_session(user_or_chat, opts \\ []) do
    opts =
      NimbleOptions.validate!(opts,
        user: [type: {:struct, User}],
        chat: [type: {:struct, Chat}],
        webhook_path: [type: :string, default: "/telegram"],
        # should we allow this?
        updates: [type: {:list, {:struct, Update}}, default: []]
      )

    Registry.add_session(user_or_chat, opts)
  end

  def reload_session(%{chat: %{id: chat_id}}) do
    Registry.get_session(chat_id)
  end

  def send_audio(session, audio, opts \\ []) do
    call_method(session, "sendAudio", opts |> Keyword.put(:audio, audio))
  end

  def send_photo(session, photo, opts \\ []) do
    call_method(session, "sendPhoto", opts |> Keyword.put(:photo, photo))
  end

  def call_method(session, method, params) do
    Webhook.post_update(
      session.webhook_path,
      build_telegram_update_for_method(
        method,
        params
        |> Keyword.put(:from, if(session.user, do: Map.from_struct(session.user)))
        |> Keyword.put(:chat, Map.from_struct(session.chat || session.user))
      )
    )

    # return updated session
    Registry.get_session(session.chat.id)
  end

  def send_message(session, text, opts \\ []) do
    call_method(session, "sendMessage", opts |> Keyword.put(:text, text))
  end

  def assert_text_matches(session, pattern) do
    case List.last(session.updates) do
      nil ->
        raise "No messages in session"

      # TODO: this should look into response instead of params, but we're not building it properly yet
      %{params: %{text: text}} ->
        cond do
          is_binary(pattern) and String.contains?(text, pattern) ->
            session

          is_struct(pattern, Regex) and Regex.match?(pattern, text) ->
            session

          is_binary(pattern) ->
            raise "Expected message text to contain '#{pattern}', but got: '#{text}'"

          true ->
            raise "Expected message text to match #{inspect(pattern)}, but got: '#{text}'"
        end

      update ->
        raise "Last update does not contain text: #{inspect(update)}"
    end
  end

  def assert_has_button(session, text) do
    find_update_with_button(session.updates, text)
    |> case do
      nil ->
        raise "No button with text #{text} found"

      # TODO: this should look into response instead of params, but we're not building it properly yet
      %{params: %{reply_markup: %{inline_keyboard: buttons}}} ->
        buttons
        |> List.flatten()
        |> Enum.find(fn %{text: button_text} -> button_text =~ text end)
        |> case do
          nil ->
            raise "No button with text #{text} found"

          _ ->
            session
        end
    end
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
              session.webhook_path,
              build_telegram_update(:callback_query,
                data: callback_data,
                from: Map.from_struct(user),
                message: update.params
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

  def build_telegram_update_for_method(method, params) do
    params =
      Keyword.validate!(params,
        from: %{},
        chat: %{},
        text: "some text",
        photo: "some photo",
        audio: "some audio",
        date: DateTime.utc_now(),
        reply_to_message: nil,
        message_id: :rand.uniform(1_000_000)
      )

    date = params[:date] |> DateTime.to_unix()

    message =
      %{
        "message_id" => params[:message_id],
        "date" => date,
        "chat" => params[:chat],
        "from" => params[:from],
        "text" => if(method == "sendMessage", do: params[:text]),
        "caption" => if(method == "sendPhoto", do: params[:caption]),
        "photo" => if(method == "sendPhoto", do: build_object(:photo, params)),
        "audio" => if(method == "sendAudio", do: params[:audio]),
        "reply_to_message" => params[:reply_to_message]
      }
      |> Map.reject(fn {_k, v} -> is_nil(v) end)

    %{"message" => message, "update_id" => :rand.uniform(1_000_000_000)}
  end

  def build_object(:photo, params) do
    [
      %{
        # TODO generate these 2 as discussed in https://chatgpt.com/c/68ed9a33-2860-8324-96ec-8d839a23c41d
        "file_id" => params[:photo],
        "file_unique_id" => "unique_#{params[:photo]}",
        "file_size" => 12345,
        "width" => 800,
        "height" => 600
      }
    ]
  end

  def build_object(:audio, params) do
    %{
      "file_id" => params[:audio],
      "file_unique_id" => "unique_#{params[:audio]}",
      "duration" => 120,
      "performer" => "Some Artist",
      "title" => "Some Title",
      "mime_type" => "audio/mpeg",
      "file_size" => 1_234_567
    }
  end

  def build_telegram_update(:message, opts) do
    opts =
      Keyword.validate!(opts,
        from: %User{},
        chat: %Chat{},
        text: "some text",
        date: DateTime.utc_now(),
        reply_to_message: nil,
        message_id: :rand.uniform(1_000_000)
      )

    date = opts[:date] |> DateTime.to_unix()

    message =
      %{
        "chat" => Map.from_struct(opts[:chat]),
        "date" => date,
        "from" => Map.from_struct(opts[:from]),
        "message_id" => opts[:message_id],
        "text" => opts[:text],
        "reply_to_message" => opts[:reply_to_message]
      }
      |> Map.reject(fn {_k, v} -> is_nil(v) end)
      |> Gramex.Utils.deep_stringify_keys()

    %{"message" => message, "update_id" => :rand.uniform(1_000_000_000)}
  end

  def build_telegram_update(:callback_query, opts) do
    opts = Keyword.validate!(opts, message: %{}, data: "", telegram_id: nil, from: %{})

    message =
      opts[:message]
      |> Map.put_new(:message_id, :rand.uniform(1_000_000))
      |> Map.put_new(:from, opts[:from])
      |> Gramex.Utils.deep_stringify_keys()

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
