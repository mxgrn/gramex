# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Gramex

Gramex is an Elixir library providing Telegram bot API helpers: an adapter-based API client, webhook parsing plugs, user data persistence, and a testing toolkit for end-to-end bot testing. It targets Elixir ~> 1.18.

## Commands

- `mix test` — run the full test suite
- `mix test path/to/test.exs` — run a single test file
- `mix test path/to/test.exs:42` — run a specific test by line number
- `mix format` — format the codebase (uses Quokka plugin for schema auto-sorting)

## Architecture

### Adapter pattern for API calls

`Gramex.Api` delegates to a configurable adapter set via `Application.get_env(:gramex, :adapter)`:
- `Gramex.ApiReq` — real HTTP adapter using the Req library (default)
- `Gramex.ApiMock` — mock adapter for tests; records bot responses into the session registry so assertions can inspect them

Always call `Gramex.Api.request/3` or `/4`, never call adapters directly.

### Webhook plugs

Two plugs work in sequence in a Phoenix pipeline:
1. `Gramex.UserDataPlug` — extracts Telegram user data from webhook params into `conn.assigns.telegram_user_data`
2. `Gramex.UserDataPersistencePlug` — upserts user data into an Ecto schema (maps Telegram fields to `telegram_*` prefixed columns)

### Update parsing

`Gramex.Updates` handles extracting user, chat, message, and payload data from Telegram webhook payloads. It also detects bot blocking via `my_chat_member` updates.

### Testing framework

`Gramex.Testing.BotCase` is an ExUnit case template that sets up the session registry and imports helpers. The testing flow:

1. `start_session/2` creates a session keyed by `chat_id`
2. Helpers like `send_message/3`, `send_photo/3`, `click_button/2` post webhook updates through `Phoenix.ConnTest` to exercise the full app pipeline
3. `Gramex.ApiMock` intercepts bot API calls and appends responses to the session's update list
4. Assertions (`assert_text/2`, `assert_has_button/2`, `assert_method/2`) inspect the last recorded update
5. `eventually/3` retries an assertion with a timeout for async behavior

Sessions are tracked by `Gramex.Testing.Sessions.Registry` (a GenServer).

## Testing conventions

- Tests use `Gramex.Case` (defined in `test/support/case.ex`) which starts the Registry, imports session helpers, and imports Mimic
- `test/support/` contains mock modules (`MockRepo`, `MockUser`) — these are available in tests via `elixirc_paths(:test)` including `test/support`
- Mocking uses the Mimic library (`Mimic.copy` in `test_helper.exs`, `stub/3` and `expect/3` in tests)
- The test adapter is set in `test_helper.exs`: `Application.put_env(:gramex, :adapter, Gramex.ApiMock)`
