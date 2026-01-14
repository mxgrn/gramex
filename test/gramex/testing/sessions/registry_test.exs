defmodule Gramex.Testing.Sessions.RegistryTest do
  use Gramex.Testing.BotCase

  alias Gramex.Testing.Sessions.Chat
  alias Gramex.Testing.Sessions.Registry
  alias Gramex.Testing.Sessions.User

  describe "adding session" do
    test "with chat" do
      chat = Chat.new()
      session = Registry.add_session(chat, webhook_path: "/some_path")
      assert session.id == chat.id
      assert session.chat.id == chat.id
    end

    test "with user" do
      user = User.new()
      session = Registry.add_session(user, webhook_path: "/some_path")
      assert session.id == user.id
      assert session.user.id == user.id
      # by default `chat` is `user`, which means a private chat
      assert session.chat.id == user.id
    end
  end
end
