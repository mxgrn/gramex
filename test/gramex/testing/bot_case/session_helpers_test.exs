defmodule Gramex.Testing.BotCase.SessionHelpersTest do
  use Gramex.Case, async: true

  alias Gramex.Testing.BotCase.SessionHelpers
  alias Gramex.Testing.Sessions.Chat
  alias Gramex.Testing.Sessions.User

  describe "start_session/2" do
    test "when User is passed, creates a private chat" do
      assert %{chat: chat, user: user} = SessionHelpers.start_session(User.new(id: 12345))

      assert chat.id == 12345
      assert user.id == 12345
    end

    test "when Chat and User are passed, assumes User posting to the Chat" do
      assert %{chat: chat, user: user} =
               SessionHelpers.start_session(Chat.new(id: 12345),
                 user: User.new(id: 23456)
               )

      assert chat.id == 12345
      assert user.id == 23456
    end
  end
end
