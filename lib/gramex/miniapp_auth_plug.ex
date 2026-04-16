defmodule Gramex.MiniappAuthPlug do
  @moduledoc """
  A Plug that authenticates requests from
  [Telegram Mini Apps](https://core.telegram.org/bots/webapps) by validating
  the `initData` signature sent by the Telegram client.

  When a user opens a Mini App, Telegram injects `initData` — a set of
  query-string parameters that includes a cryptographic `hash`. This plug
  verifies that hash against your bot token using the algorithm described in
  the [Telegram documentation](https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app),
  ensuring the request genuinely originates from Telegram.

  ## Usage

  Add the plug to your Phoenix pipeline or router, passing the bot token via
  the `:token` option:

      # Compile-time token (available at build time)
      plug Gramex.MiniappAuthPlug,
        token: Application.compile_env(:my_app, :telegram_bot)[:token]

      # Runtime token (e.g. from config/runtime.exs or environment variables)
      plug Gramex.MiniappAuthPlug, token: &MyApp.telegram_token/0

  ## Behaviour

  ### Successful authentication

  On a valid hash the plug stores three values in the session:

  | Session key          | Value                                                                 |
  |----------------------|-----------------------------------------------------------------------|
  | `"telegram_user_id"` | The Telegram user's numeric ID (from the `user` JSON in `initData`). |
  | `"start_param"`      | The decoded `start_param` (see below), or `nil` if absent.           |
  | `"query_string"`     | The raw query string from `conn`, preserved for downstream use.       |

  If `start_param` is present and contains a `"path"` key, the plug issues a
  **302 redirect** to that path. This is useful for deep-linking into specific
  pages of your Mini App.

  ### Failed authentication

  If the hash does not match, the plug responds with **401 Not Authorized**
  and halts the connection.

  ### No hash parameter

  Requests that don't contain a `"hash"` parameter are passed through
  unchanged — the plug is a no-op.

  ## The `start_param` convention

  Telegram's `start_param` is a single string. This plug expects it to be a
  Base64url-encoded JSON object, which it decodes automatically. For example,
  to deep-link a user to `/dashboard`:

      start_param = %{"path" => "/dashboard"} |> JSON.encode!() |> Base.url_encode64()

  ## Validation algorithm

  The hash is verified using HMAC-SHA256 as specified by Telegram:

  1. Compute `secret_key = HMAC-SHA256("WebAppData", bot_token)`.
  2. Build `data_check_string` by sorting the remaining `initData` fields
     alphabetically by key and joining them as `key=value` pairs separated
     by newlines.
  3. Compute `hash = HMAC-SHA256(secret_key, data_check_string)`.
  4. Compare the computed hash with the received `hash` parameter.

  """
  import Plug.Conn


  @doc false
  def init(opts), do: opts

  @doc """
  Validates the Telegram `initData` hash and sets session values.

  Pattern-matches on `params["hash"]` — requests without it fall through to
  the catch-all clause which returns the conn unchanged.
  """
  def call(%{params: %{"hash" => _} = params} = conn, opts) do
    start_param =
      params["start_param"] &&
        params["start_param"] |> URI.decode() |> Base.url_decode64!() |> JSON.decode!()

    token = resolve_token(opts[:token])

    with {:ok, %{"user" => user}} <- validate_web_app_init_data(params, token),
         {:ok, user} <- JSON.decode(user) do
      conn
      |> put_session("telegram_user_id", user["id"])
      |> put_session("start_param", start_param)
      |> put_session("query_string", conn.query_string)
      |> then(fn conn ->
        if redirect_path = start_param["path"] do
          # redirecting, from https://elixirforum.com/t/url-redirect/18890/5
          conn
          |> resp(:found, "")
          |> put_resp_header("location", redirect_path)
        else
          conn
        end
      end)
    else
      _e ->
        conn
        |> resp(401, "Not authorized")
        |> halt()
    end
  end

  # Wrong params, probably just a random request from the internets
  def call(conn, _), do: conn

  defp validate_web_app_init_data(tg_init_data, bot_api_token) when is_binary(bot_api_token) do
    {received_hash, decoded_map} =
      Map.pop(tg_init_data, "hash")

    data_check_string =
      decoded_map
      |> Enum.sort(fn {k1, _v1}, {k2, _v2} -> k1 <= k2 end)
      |> Enum.map_join("\n", fn {k, v} -> "#{k}=#{v}" end)

    calculated_hash =
      "WebAppData"
      |> hmac(bot_api_token)
      |> hmac(data_check_string)
      |> Base.encode16(case: :lower)

    if received_hash == calculated_hash do
      {:ok, decoded_map}
    else
      {:error, :hash_mismatch}
    end
  end

  defp resolve_token(fun) when is_function(fun, 0), do: fun.()
  defp resolve_token(token) when is_binary(token), do: token

  defp hmac(key, data) do
    :crypto.mac(:hmac, :sha256, key, data)
  end
end
