defmodule Gramex.Testing.BotCase.SessionHelpersTest do
  use Gramex.Case, async: true

  alias Gramex.Testing.BotCase.SessionHelpers
  alias Gramex.Testing.Sessions.Chat
  alias Gramex.Testing.Sessions.User
  alias Gramex.Testing.Webhook

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

    test "for Chat sessions, passing User is optional" do
      assert %{chat: chat, user: nil} = SessionHelpers.start_session(Chat.new(id: 12345))
      assert chat.id == 12345
    end
  end

  describe "add_bot_to_group/2" do
    test "posts my_chat_member update with status 'member'" do
      chat = Chat.new(id: -12345, type: "group", title: "Test Group")
      user = User.new(id: 111)
      bot = User.new(id: 999, is_bot: true, first_name: "TestBot")

      session = start_session(chat, user: user)

      expect(Webhook, :post_update, fn _path, update ->
        assert %{
                 "my_chat_member" => %{
                   "chat" => %{"id" => -12345},
                   "from" => %{"id" => 111},
                   "new_chat_member" => %{"status" => "member", "user" => %{"id" => 999}},
                   "old_chat_member" => %{"status" => "left", "user" => %{"id" => 999}}
                 }
               } = update

        %{}
      end)

      add_bot_to_group(session, bot)
    end

    test "throws exception for non-chat session" do
      user = User.new()
      bot = User.new(is_bot: true)

      session = start_session(user)

      assert_raise ArgumentError, fn ->
        add_bot_to_group(session, bot)
      end
    end
  end

  describe "remove_bot_from_group/2" do
    test "posts my_chat_member update with status 'kicked'" do
      chat = Chat.new(id: -12345, type: "group", title: "Test Group")
      user = User.new(id: 111)
      bot = User.new(id: 999, is_bot: true, first_name: "TestBot")

      session = start_session(chat, user: user)

      expect(Webhook, :post_update, fn _path, update ->
        assert %{
                 "my_chat_member" => %{
                   "chat" => %{"id" => -12345},
                   "from" => %{"id" => 111},
                   "new_chat_member" => %{"status" => "kicked", "user" => %{"id" => 999}},
                   "old_chat_member" => %{"status" => "member", "user" => %{"id" => 999}}
                 }
               } = update

        %{}
      end)

      remove_bot_from_group(session, bot)
    end

    test "throws exception for non-chat session" do
      user = User.new()
      bot = User.new(is_bot: true)

      session = start_session(user)

      assert_raise ArgumentError, fn ->
        remove_bot_from_group(session, bot)
      end
    end
  end
end
