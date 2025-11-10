defmodule Gramex.ApiMock do
  alias Gramex.Testing.Sessions.Registry
  alias Gramex.Testing.Sessions.Update

  def request(_token, method, %{chat_id: chat_id} = params)
      when method in ["sendInvoice", "sendMessage", "sendPhoto", "sendVoice"] do
    # make these incremental?
    update_id = :rand.uniform(1_000_000)
    message_id = :rand.uniform(1_000_000)

    session = Registry.get_session(chat_id)

    response =
      build_response_by_method(method, params)
      |> Map.put(:chat, Map.from_struct(session.chat))
      |> Map.put(:from, Map.from_struct(session.user))
      |> Map.put(:message_id, message_id)
      |> normalize_response()

    Registry.append_to_session(chat_id, %Update{
      method: method,
      update_id: update_id,
      params: params,
      response: response
    })

    {:ok, response}
  end

  def request(_token, "setWebhook", _params) do
    response =
      true
      |> normalize_response()

    {:ok, response}
  end

  # do NOT store this in action, as it doesn't result in any sort of a message
  def request(_token, "sendChatAction", _params) do
    response =
      true
      |> normalize_response()

    {:ok, response}
  end

  def request(_token, "deleteMessage" = method, %{chat_id: chat_id} = params) do
    update_id = :rand.uniform(1_000_000)

    response =
      true
      |> normalize_response()

    Registry.append_to_session(chat_id, %Update{
      method: method,
      update_id: update_id,
      params: params,
      response: response
    })

    {:ok, response}
  end

  def request(_token, "editMessageText" = method, %{chat_id: chat_id} = params) do
    update_id = :rand.uniform(1_000_000)
    message_id = :rand.uniform(1_000_000)

    response =
      %{message_id: message_id}
      |> normalize_response()

    Registry.append_to_session(chat_id, %Update{
      method: method,
      update_id: update_id,
      params: params,
      response: response
    })

    {:ok, response}
  end

  def request(_token, method, _update) do
    raise "Not implemented: #{method}"
  end

  defp normalize_response(response) when is_map(response) do
    response
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
    |> Map.new()
    |> Jason.encode!()
    |> Jason.decode!()
  end

  defp normalize_response(response) do
    response
    |> Jason.encode!()
    |> Jason.decode!()
  end

  # veeery simplified, see https://core.telegram.org/bots/api#message
  defp build_response_by_method("sendMessage", params) do
    %{
      text: params[:text]
    }
  end

  defp build_response_by_method("sendPhoto", params) do
    %{
      photo: params[:photo]
    }
  end

  defp build_response_by_method("sendVoice", params) do
    %{
      voice: params[:voice]
    }
  end

  defp build_response_by_method("sendInvoice", params) do
    %{
      invoice: %{
        title: params[:title],
        description: params[:description],
        currency: params[:currency],
        total_amount: params[:total_amount]
      }
    }
  end
end
