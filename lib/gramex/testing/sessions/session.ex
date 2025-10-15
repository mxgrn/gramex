defmodule Gramex.Testing.Sessions.Session do
  alias Gramex.Testing.Sessions.Chat
  alias Gramex.Testing.Sessions.User

  defstruct [:user, :chat, :webhook_path, :id, updates: []]

  def new(user_or_chat, opts \\ [])

  def new(%User{} = user, opts) do
    opts =
      Keyword.validate!(opts,
        id: :rand.uniform(1_000_000_000),
        chat: user,
        updates: [],
        webhook_path: "/telegram"
      )

    %__MODULE__{
      id: opts[:chat].id,
      user: user,
      chat: opts[:chat],
      updates: opts[:updates],
      webhook_path: opts[:webhook_path]
    }
  end

  def new(%Chat{} = chat, opts) do
    opts =
      Keyword.validate!(opts, user: nil, updates: [], webhook_path: "/telegram")

    %__MODULE__{
      id: chat.id,
      chat: chat,
      user: opts[:user],
      updates: opts[:updates],
      webhook_path: opts[:webhook_path]
    }
  end
end
