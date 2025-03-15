defmodule Telex.Api do
  @moduledoc """
  A lot of code relies on this API being predictible and consistent.
  """
  require Logger

  @doc """
  `method` should be as per the Telegram API documentation, e.g. "getMe" or :getMe.
  """
  def request(token, method, params \\ %{}) do
    Logger.info("Sending request to Telegram API: #{method} with params: #{inspect(params)}")

    # Telegram supports both POST and GET, but Req provides retries for GET, e.g. for `{:error, %Req.TransportError{reason: :closed}}`, so, that's what we use.
    "https://api.telegram.org/bot#{token}/#{method}"
    |> Req.get(json: params)
    |> case do
      # When response contains result we need to check, we pass it along
      {:ok, %{body: %{"ok" => true, "result" => result}}} ->
        {:ok, result}

      # When response doesn't contain result, we simply return :ok
      {:ok, %{:body => %{"ok" => true}}} ->
        :ok

      # bot blocked
      {:ok, %{:body => %{"ok" => false, "description" => description, "error_code" => 403}}} ->
        msg = "Telex got back error_code: 403, description: #{description}"
        Logger.warning(msg)

        # or maybe return error_code instead? this depends on whether we pass it to the user or keep it to ourselves
        {:blocked, description}

      # for example, telegram_id doesn't exist (any more)
      {:ok, %{:body => %{"ok" => false, "description" => description, "error_code" => 400}}} ->
        msg = "Telex got back error_code: 400, description: #{description}"
        Logger.warning(msg)

        # or maybe return error_code instead? this depends on whether we pass it to the user or keep it to ourselves
        {:invalid_request, description}

      # other errors
      {:ok, %{:body => %{"ok" => false, "description" => description, "error_code" => error_code}}} ->
        msg =
          "Telex got back error_code: #{error_code}, description: #{description}"

        Logger.warning(msg)

        # or maybe return error_code instead? this depends on whether we pass it to the user or keep it to ourselves
        {:error, description}

      e ->
        msg = "Telex: #{inspect(e)}"
        Logger.warning(msg)
        {:error, msg}
    end
  end
end
