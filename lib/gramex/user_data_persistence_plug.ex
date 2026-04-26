defmodule Gramex.UserDataPersistencePlug do
  @moduledoc """
  Keeps user data in the database up-to-date.

  Usage example:

  ```elixir
  plug Gramex.UserDataPlug
  plug Gramex.UserDataPersistencePlug, repo: MyApp.Repo, schema: MyApp.User, changeset: :changeset
  ```

  ## Options

  - `:repo` (required) — the Ecto repo module
  - `:schema` (required) — the Ecto schema module
  - `:changeset` — changeset function name on the schema (default: `:changeset`)
  - `:user_assigns_key` — key to assign the persisted user in `conn.assigns` (default: `:current_user`)
  - `:field_mapping` — a map overriding how Telegram fields map to database columns.
    Only the keys you provide are overridden; the rest keep their defaults:

        %{
          id: :telegram_id,
          username: :telegram_username,
          is_bot: :telegram_is_bot,
          first_name: :telegram_first_name,
          last_name: :telegram_last_name,
          language_code: :telegram_language_code,
          is_premium: :telegram_is_premium,
          bot_blocked_at: :telegram_bot_blocked_at,
          last_message: :telegram_last_message
        }

    Example — drop the `telegram_` prefix for name fields:

        plug Gramex.UserDataPersistencePlug,
          repo: MyApp.Repo,
          schema: MyApp.User,
          field_mapping: %{first_name: :first_name, last_name: :last_name}
  """

  @behaviour Plug

  require Logger

  @default_field_mapping %{
    id: :telegram_id,
    username: :telegram_username,
    is_bot: :telegram_is_bot,
    first_name: :telegram_first_name,
    last_name: :telegram_last_name,
    language_code: :telegram_language_code,
    is_premium: :telegram_is_premium,
    bot_blocked_at: :telegram_bot_blocked_at,
    last_message: :telegram_last_message
  }

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    repo = opts[:repo] || raise("repo is required")
    schema = opts[:schema] || raise("schema is required")
    changeset = Keyword.get(opts, :changeset, :changeset)
    user_assigns_key = Keyword.get(opts, :user_assigns_key, :current_user)
    mapped = Map.merge(@default_field_mapping, Keyword.get(opts, :field_mapping, %{}))

    user_data = conn.assigns.telegram_user_data

    user_attrs =
      %{
        mapped.id => user_data["id"],
        mapped.username => user_data["username"],
        mapped.is_bot => user_data["is_bot"],
        mapped.first_name => user_data["first_name"],
        mapped.last_name => user_data["last_name"],
        mapped.language_code => user_data["language_code"],
        mapped.is_premium => !!user_data["is_premium"],
        mapped.bot_blocked_at => user_data["gramex_bot_blocked_at"],
        updated_at: DateTime.utc_now()
      }
      |> then(fn attrs ->
        if is_map(user_data) && Map.has_key?(user_data, "last_message") do
          Map.put(attrs, mapped.last_message, user_data["last_message"])
        else
          attrs
        end
      end)

    if user_data["id"] do
      repo.transact(fn ->
        case repo.get_by(schema, [{mapped.id, user_data["id"]}]) do
          nil ->
            apply(schema, changeset, [struct(schema), user_attrs])
            |> repo.insert!(returning: true)

          existing_user ->
            apply(schema, changeset, [existing_user, user_attrs])
            |> repo.update!(returning: true)
        end
        |> then(&{:ok, &1})
      end)
    else
      Logger.warning("Telegram user data missing 'id' field: #{inspect(user_data)}")
      {:error, :no_telegram_id}
    end
    |> case do
      {:ok, user} ->
        user

      {:error, reason} ->
        Logger.info("Failed to persist user data: #{inspect(reason)}")
        nil
    end
    |> then(&Plug.Conn.assign(conn, user_assigns_key, &1))
  end
end
