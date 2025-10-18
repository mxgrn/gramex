# Gramex

Telegram bot helpers for Elixir applications using Plug or Phoenix. Gramex wraps the Telegram Bot API, extracts user data from webhook payloads, keeps your database in sync, and ships a lightweight testing toolkit so you can exercise your bots end-to-end.

> ℹ️ Gramex is under active development. The public API is still evolving, but it is already useful for real Telegram bot projects.

## Features
- **Adapter-based API client** – `Gramex.Api` delegates requests to a configurable adapter (default: `Req`) and normalises common Telegram error cases.
- **Webhook parsing** – `Gramex.Webhook` extracts users and message metadata from Telegram updates, with logging around unexpected payloads.
- **Plug helpers** – `Gramex.UserDataPlug` assigns Telegram user data to the connection; `Gramex.UserDataPersistencePlug` keeps your Ecto schema in sync.
- **Testing harness** – `Gramex.Testing.BotCase` spins up a session registry, feeds webhook updates through your app, and provides helpers for simulating messages, callback buttons, photos, audio, and more.
- **Mock API adapter** – `Gramex.ApiMock` records outbound calls during tests so you can assert on the bot’s behaviour without hitting Telegram.

## Installation
Add Gramex to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gramex, "~> 0.0.4"},
    # Gramex relies on Jason for JSON encoding/decoding
    {:jason, "~> 1.4"}
  ]
end
```

Fetch the dependencies:

```bash
mix deps.get
```

Until the library is published on [hex.pm](https://hex.pm/), you can point the dependency at GitHub instead:

```elixir
{:gramex, github: "mxgrn/gramex"}
```

## Configuration
Configure the default adapter in `config/config.exs` (optional – `Gramex.ApiReq` is the default):

```elixir
config :gramex, :adapter, Gramex.ApiReq
```

For your test environment, provide an endpoint so the testing helpers can drive your Phoenix app:

```elixir
# config/test.exs
config :gramex, :endpoint, MyAppWeb.Endpoint
```

Switch to the mock adapter when you do not want to hit Telegram:

```elixir
config :gramex, :adapter, Gramex.ApiMock
```

## Usage

### Handling Telegram webhooks

Wire the provided plugs into your Phoenix controller or Plug pipeline to extract user data and keep it persisted:

```elixir
defmodule MyAppWeb.TelegramWebhookController do
  use MyAppWeb, :controller

  plug Gramex.UserDataPlug, halt_if_nil: true

  plug Gramex.UserDataPersistencePlug,
    repo: MyApp.Repo,
    schema: MyApp.Accounts.User,
    changeset: :telegram_changeset,
    user_assigns_key: :telegram_user

  def create(conn, _params) do
    user = conn.assigns.telegram_user

    {:ok, _message} =
      Gramex.Api.request(
        Application.fetch_env!(:my_app, :telegram_bot_token),
        "sendMessage",
        %{chat_id: user.telegram_id, text: "Thanks for reaching out!"}
      )

    json(conn, %{ok: true})
  end
end
```

`Gramex.UserDataPlug` places the Telegram user map under `conn.assigns.telegram_user_data`. Setting `halt_if_nil: true` short-circuits the request if no user can be extracted (for example, channel posts). `Gramex.UserDataPersistencePlug` expects your schema to expose fields such as `telegram_id`, `telegram_username`, `telegram_first_name`, `telegram_last_name`, `telegram_language_code`, and optionally `telegram_last_message`. Override `:changeset` if you use a custom constructor.

### Calling the Telegram Bot API

`Gramex.Api.request/3` normalises success and error responses:

```elixir
case Gramex.Api.request(bot_token, "sendMessage", %{chat_id: chat_id, text: "Hello"}) do
  {:ok, %{"message_id" => message_id}} ->
    Logger.info("Message sent: #{message_id}")

  {:blocked, reason} ->
    Logger.warning("User blocked the bot: #{reason}")

  {:invalid_request, reason} ->
    {:error, reason}

  {:error, reason} ->
    {:error, reason}
end
```

### Testing helpers

Use `Gramex.Testing.BotCase` in your test modules to simulate real Telegram traffic:

```elixir
defmodule MyApp.Telegram.BotTest do
  use Gramex.Testing.BotCase, async: true

  alias Gramex.Testing.Sessions.User

  test "greets the user" do
    session = start_session(User.new())

    session
    |> send_message("Hi bot!")
    |> assert_text_matches("Hello")
  end
end
```

Key helpers include:

- `start_session/2` – spin up a private or group chat session backed by the `Registry`.
- `send_message/3`, `send_photo/3`, `send_audio/3` – send updates through your webhook.
- `assert_text_matches/2` and `assert_has_button/2` – assert on the most recent bot response.
- `click_button/2` – simulate a callback query when the bot renders inline keyboards.

Because the helpers post through `Phoenix.ConnTest`, your application pipeline (plugs, controllers, business logic) is exercised exactly as Telegram would.

## Development

- Run the test suite with `mix test`.
- Format the codebase with `mix format`.
- Generate HTML documentation with `mix docs` (sets `source_ref` based on the version in `mix.exs`).

## License

Gramex is released under the MIT License.
