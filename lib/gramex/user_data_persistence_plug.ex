defmodule Gramex.UserDataPersistencePlug do
  @moduledoc """
  Keeps user data in the database up-to-date.

  Usage example:

  ```elixir
  plug Gramex.UserDataPlug
  plug Gramex.UserDataPersistencePlug, repo: MyApp.Repo, schema: MyApp.User, changeset: :changeset
  ```
  """

  @behaviour Plug

  require Logger

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    repo = opts[:repo] || raise("repo is required")
    schema = opts[:schema] || raise("schema is required")
    changeset = Keyword.get(opts, :changeset, :changeset)
    user_assigns_key = Keyword.get(opts, :user_assigns_key, :current_user)
    # ... in the future also: field mapping, etc.

    user_data = conn.assigns.telegram_user_data

    user_attrs =
      %{
        telegram_id: user_data["id"],
        telegram_username: user_data["username"],
        telegram_is_bot: user_data["is_bot"],
        telegram_first_name: user_data["first_name"],
        telegram_last_name: user_data["last_name"],
        telegram_language_code: user_data["language_code"],
        telegram_is_premium: !!user_data["is_premium"],
        telegram_bot_blocked_at: user_data["gramex_bot_blocked_at"],
        updated_at: DateTime.utc_now()
      }
      |> then(fn attrs ->
        # This is instead of passing nil in the map above, as we do NOT want to override telegram_last_message with nil
        if Map.has_key?(user_data, "last_message") do
          Map.put(attrs, :telegram_last_message, user_data["last_message"])
        else
          attrs
        end
      end)

    if user_data["id"] do
      repo.transact(fn ->
        case repo.get_by(schema, telegram_id: user_data["id"]) do
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
