defmodule Gramex.ApiMock do
  alias Gramex.ApiMock.Message
  alias Gramex.Testing.BotCase.Registry
  alias Gramex.Testing.BotCase.Update

  def request(_token, "sendMessage" = method, %{chat_id: chat_id} = params) do
    # TODO: make these incremental
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
