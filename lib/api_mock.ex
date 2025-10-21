defmodule Gramex.ApiMock do
  alias Gramex.ApiMock.Message
  alias Gramex.Testing.Sessions.Registry
  alias Gramex.Testing.Sessions.Update

  def request(_token, method, %{chat_id: chat_id} = params)
      when method in ["sendMessage", "sendPhoto", "sendVoice"] do
    # TODO: make these incremental
    update_id = :rand.uniform(1_000_000)
    message_id = :rand.uniform(1_000_000)

    # veeery simplified, see https://core.telegram.org/bots/api#message
    response =
      %Message{message_id: message_id, text: params[:text]}
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
      %Message{message_id: message_id}
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

  defp normalize_response(response) when is_struct(response) do
    response
    |> Map.from_struct()
    |> Jason.encode!()
    |> Jason.decode!()
  end

  defp normalize_response(response) do
    response
    |> Jason.encode!()
    |> Jason.decode!()
  end
end
