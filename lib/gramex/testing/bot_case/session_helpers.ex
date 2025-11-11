defmodule Gramex.Testing.BotCase.SessionHelpers do
  @moduledoc """
  Helpers that get imported when `using` `Gramex.Testing.BotCase`.

  Most of these methods is a bot calling us, on behalf of a user, _not_ the other way round.
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

  def send_message(session, text, opts \\ []) do
    send_update(session, :message, opts |> Keyword.put(:text, text))
  end

  def send_audio(session, audio, opts \\ []) do
    send_update(session, :audio, opts |> Keyword.put(:audio, audio))
  end

  def send_photo(session, photo, opts \\ []) do
    send_update(session, :photo, opts |> Keyword.put(:photo, photo))
  end

  def send_successful_payment(session, opts \\ []) do
    send_update(session, :successful_payment, opts)
  end

  def send_message_reaction(session, reaction, opts \\ []) do
    send_update(session, :message_reaction, Keyword.put(opts, :emoji, reaction))
  end

  def send_update(session, method, opts) do
    Webhook.post_update(
      session.webhook_path,
      build_telegram_update_for_method(
        method,
        opts
        |> Keyword.put(:from, if(session.user, do: Map.from_struct(session.user)))
        |> Keyword.put(
          :chat,
          Map.from_struct(session.chat || session.user)
        )
        |> Keyword.put(:last_update, List.last(session.updates))
      )
    )

    # return updated session
    Registry.get_session(session.chat.id)
  end

  def assert_text(session, pattern) do
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

  def assert_method(session, method) do
    case List.last(session.updates) do
      nil ->
        raise "No messages in session"

      %{method: ^method} ->
        session

      %{method: other_method} ->
        raise "Expected method '#{method}', but got '#{other_method}'"
    end
  end

  def assert_has_button(session, text) do
    find_update_with_button(session.updates, text)
    |> case do
      # TODO: this should look into response instead of params, but we're not building it properly yet
      %{params: %{reply_markup: %{inline_keyboard: buttons}}} ->
        buttons
        |> List.flatten()
        |> Enum.find(fn %{text: button_text} -> button_text =~ text end)
        |> case do
          nil ->
            raise "No button with text '#{text}' found"

          _ ->
            session
        end
    end
  end

  def assert_invoice(session, caption) do
    List.last(session.updates)
    |> case do
      %{response: %{"invoice" => %{"title" => received_title}}} when is_binary(received_title) ->
        if received_title =~ caption do
          session
        else
          raise "Expected invoice message title to contain '#{caption}', but got: '#{received_title}'"
        end

      %{response: %{"invoice" => _}} ->
        raise "No title found in invoice"

      _ ->
        raise "No invoice found in the update"
    end
  end

  def assert_voice(session, caption) do
    List.last(session.updates)
    |> case do
      %{params: %{voice: _, caption: received_caption}} when is_binary(received_caption) ->
        if received_caption =~ caption do
          session
        else
          raise "Expected voice message caption to contain '#{caption}', but got: '#{received_caption}'"
        end

      %{params: %{voice: _}} ->
        raise "No caption found in voice message"

      _ ->
        raise "No voice message found"
    end
  end

  def click_button(%{user: user} = session, text) do
    find_update_with_button(session.updates, text)
    |> case do
      # TODO: this should look into response instead of params, but we're not building it properly yet
      %{params: %{reply_markup: %{inline_keyboard: buttons}}} = update ->
        buttons
        |> List.flatten()
        |> Enum.find(fn %{text: button_text} -> button_text =~ text end)
        |> case do
          nil ->
            raise "No button with text '#{text}' found"

          %{callback_data: callback_data} ->
            Webhook.post_update(
              session.webhook_path,
              build_telegram_update(:callback_query,
                data: callback_data,
                from: Map.from_struct(user),
                message: update.params |> Map.put(:message_id, update.response.message_id)
              )
            )

            session

          _ ->
            raise "No callback_data found for button '#{text}'"
        end
    end

    Registry.get_session(user.id)
  end

  def refute_has_button(%{user: user} = session, text) do
    session.updates
    |> List.last()
    |> case do
      # TODO: this should look into response instead of params, but we're not building it properly yet
      %{params: %{reply_markup: %{inline_keyboard: buttons}}} ->
        buttons
        |> List.flatten()
        |> Enum.find(fn %{text: button_text} -> button_text =~ text end)
        |> case do
          nil ->
            session

          %{callback_data: _} ->
            raise "I didn’t expect to, but I found a button labeled '#{text}'"
        end
    end

    Registry.get_session(user.id)
  end

  @doc """
  Repeatedly runs the given `assertion_fun` until it passes or the timeout is reached.
  Useful for testing asynchronous behavior.

  Examples:

      eventually(session, fn session ->
        assert_text(session, "Expected Text")
      end)

      eventually(&click_button(&1, "Click Me"))
  """
  def eventually(session, assertion_fun, opts \\ []) when is_function(assertion_fun, 1) do
    timeout = opts[:timeout] || 100
    interval = opts[:interval] || 20
    start_time = System.monotonic_time(:millisecond)
    do_eventually(session, assertion_fun, start_time, timeout, interval)
  end

  defp do_eventually(session, assertion_fun, start_time, timeout, interval) do
    assertion_fun.(session)
    session
  rescue
    e in [ExUnit.AssertionError, RuntimeError, MatchError] ->
      current_time = System.monotonic_time(:millisecond)

      if current_time - start_time < timeout do
        :timer.sleep(interval)

        session
        |> reload_session()
        |> do_eventually(assertion_fun, start_time, timeout, interval)
      else
        reraise e, __STACKTRACE__
      end
  end

  defp find_update_with_button([], _text) do
    raise "Session is empty"
  end

  # for now only checks the last update
  defp find_update_with_button(updates, text) do
    List.last(updates)
    |> Map.from_struct()
    |> Gramex.Utils.deep_atomize_keys()
    |> case do
      %{params: %{reply_markup: %{inline_keyboard: buttons}}} = update ->
        buttons =
          buttons
          |> List.flatten()

        if Enum.any?(buttons, fn %{text: button_text} -> button_text =~ text end) do
          update
        else
          raise "No button with text '#{text}' found.\nButtons in the last message: #{Enum.map_join(buttons, ", ", &"'#{&1.text}'")}"
        end

      _ ->
        raise "No buttons found in the last message"
    end
  end

  def build_telegram_update_for_method(:message_reaction, opts) do
    build_object(:message_reaction, opts)
  end

  def build_telegram_update_for_method(method, opts) do
    date = (opts[:date] || DateTime.utc_now()) |> DateTime.to_unix()
    message_id = opts[:message_id] || :rand.uniform(1_000_000)

    message =
      %{
        "message_id" => message_id,
        "date" => date,
        "chat" => opts[:chat],
        "from" => opts[:from],
        "text" => if(method == :message, do: opts[:text]),
        "caption" => if(method == :photo, do: opts[:caption]),
        "photo" => if(method == :photo, do: build_object(:photo, opts)),
        "audio" => if(method == :audio, do: opts[:audio]),
        "reply_to_message" => opts[:reply_to_message],
        "successful_payment" =>
          if(method == :successful_payment, do: build_object(:successful_payment, opts))
      }
      |> Map.reject(fn {_k, v} -> is_nil(v) end)

    %{"message" => message, "update_id" => :rand.uniform(1_000_000_000)}
  end

  def build_object(:successful_payment, opts) do
    %{
      "currency" => "XTR",
      "total_amount" => opts[:total_amount] || 1000,
      "invoice_payload" => opts[:invoice_payload] || "some_payload",
      "shipping_option_id" => "some_option",
      "telegram_payment_charge_id" => "charge_id_123",
      "provider_payment_charge_id" => "provider_charge_id_456"
    }
  end

  def build_object(:message_reaction, opts) do
    message_id = opts[:last_update].response["message_id"]
    opts[:last_update] |> dbg()

    %{
      "message_reaction" => %{
        "chat" => build_object(:chat, opts),
        "date" => 1_762_651_325,
        "message_id" => message_id,
        "new_reaction" => [%{"emoji" => opts[:emoji], "type" => "emoji"}],
        "old_reaction" => [],
        "user" => opts[:from] || build_object(:user, opts)
      },
      "update_id" => 262_155_568
    }
  end

  def build_object(:photo, opts) do
    [
      %{
        # TODO generate these 2 as discussed in https://chatgpt.com/c/68ed9a33-2860-8324-96ec-8d839a23c41d
        "file_id" => opts[:photo],
        "file_unique_id" => "unique_#{opts[:photo]}",
        "file_size" => 12345,
        "width" => 800,
        "height" => 600
      }
    ]
  end

  def build_object(:audio, opts) do
    %{
      "file_id" => opts[:audio],
      "file_unique_id" => "unique_#{opts[:audio]}",
      "duration" => 120,
      "performer" => "Some Artist",
      "title" => "Some Title",
      "mime_type" => "audio/mpeg",
      "file_size" => 1_234_567
    }
  end

  def build_object(:chat, opts) do
    %{
      "id" => opts[:chat_id] || :rand.uniform(1_000_000_000),
      "type" => "private",
      "first_name" => "Test",
      "last_name" => "User",
      "username" => "testuser"
    }
  end

  def build_object(:user, opts) do
    %{
      "id" => opts[:chat_id] || :rand.uniform(1_000_000_000),
      "is_bot" => false,
      "first_name" => "Test",
      "last_name" => "User",
      "username" => "testuser"
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
      |> Map.delete(:chat_id)
      |> Map.put_new(:message_id, :rand.uniform(1_000_000))
      |> Map.put_new(:chat, build_object(:chat, opts[:message]))
      |> Map.put_new(:from, build_object(:user, opts[:message]))
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
