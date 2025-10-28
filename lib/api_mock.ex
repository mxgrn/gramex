defmodule Gramex.ApiMock do
  alias Gramex.Testing.Sessions.Registry
  alias Gramex.Testing.Sessions.Update

  def request(_token, method, %{chat_id: chat_id} = params)
      when method in ["sendInvoice", "sendMessage", "sendPhoto", "sendVoice"] do
    # make these incremental?
    update_id = :rand.uniform(1_000_000)
    message_id = :rand.uniform(1_000_000)

    response =
      build_response_by_method(method, message_id, params)
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

  def request(_token, "sendChatAction" = method, %{chat_id: chat_id} = params) do
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
  defp build_response_by_method("sendMessage", message_id, params) do
    %{
      message_id: message_id,
      text: params[:text]
    }
  end

  defp build_response_by_method("sendPhoto", message_id, params) do
    %{
      message_id: message_id,
      photo: params[:photo]
    }
  end

  defp build_response_by_method("sendVoice", message_id, params) do
    %{
      message_id: message_id,
      voice: params[:voice]
    }
  end

  defp build_response_by_method("sendInvoice", message_id, params) do
    %{
      message_id: message_id,
      invoice: %{
        title: params[:title],
        description: params[:description],
        currency: params[:currency],
        total_amount: params[:total_amount]
      }
    }
  end
end
