defmodule Gramex.Testing.SessionTest do
  use Gramex.Case

  alias Gramex.Api
  alias Gramex.Testing.Sessions.User
  alias Gramex.Testing.Webhook

  @chat_id 123_456

  describe "any action" do
    test "passes provided webhook path to the Api.request/3" do
      user = User.new(id: @chat_id)

      start_session(user, webhook_path: "/custom_path")

      expect(Webhook, :post_update, fn path, update ->
        assert path == "/custom_path"
        assert %{"message" => %{"text" => "Hello", "chat" => %{"id" => @chat_id}}} = update
        %{}
      end)

      Api.request(nil, "sendMessage", %{chat_id: @chat_id, text: "Hello"})
    end
  end

  describe "assert_has_text/2" do
    test "passes when text contains string" do
      user = User.new(id: @chat_id)

      session = start_session(user)

      Api.request(nil, "sendMessage", %{
        chat_id: @chat_id,
        text: "Welcome to the bot! How are you today?"
      })

      session
      |> reload_session()
      |> assert_has_text("Welcome")
      |> assert_has_text("How are you")
    end

    test "passes when text matches regex" do
      user = User.new(id: @chat_id)

      session = start_session(user)

      Api.request(nil, "sendMessage", %{
        chat_id: @chat_id,
        text: "Your code is: 12345"
      })

      session
      |> reload_session()
      |> assert_has_text(~r/code is: \d+/)
    end

    test "raises when text does not contain string" do
      user = User.new(id: @chat_id)

      session = start_session(user)

      Api.request(nil, "sendMessage", %{
        chat_id: @chat_id,
        text: "Welcome to the bot!"
      })

      assert_raise RuntimeError, ~r/Expected message text to contain 'Goodbye'/, fn ->
        session
        |> reload_session()
        |> assert_has_text("Goodbye")
      end
    end

    test "raises when text does not match regex" do
      user = User.new(id: @chat_id)

      session = start_session(user)

      Api.request(nil, "sendMessage", %{
        chat_id: @chat_id,
        text: "Hello world"
      })

      assert_raise RuntimeError, ~r/Expected message text to match/, fn ->
        session
        |> reload_session()
        |> assert_has_text(~r/^\d+$/)
      end
    end
  end

  describe "assert_has_button/2" do
    test "passes when button exists" do
      user = User.new(id: @chat_id)

      session = start_session(user)

      Api.request(nil, "sendMessage", %{
        chat_id: @chat_id,
        text: "Welcome to the bot! How are you today?",
        reply_markup: %{
          inline_keyboard: [
            [%{callback_data: "feedback", text: "Good!"}],
            [%{callback_data: "feedback", text: "So-so"}]
          ]
        }
      })

      session
      |> reload_session()
      |> assert_has_button("Good")
      |> assert_has_button("So-so")
    end

    test "raises when button does not exist" do
      user = User.new(id: @chat_id)

      session = start_session(user)

      Api.request(nil, "sendMessage", %{
        chat_id: @chat_id,
        text: "Welcome to the bot! How are you today?",
        reply_markup: %{
          inline_keyboard: [
            [%{callback_data: "feedback", text: "Good!"}]
          ]
        }
      })

      assert_raise RuntimeError, ~r/No button with text Bad found/, fn ->
        session
        |> reload_session()
        |> assert_has_button("Bad")
      end
    end
  end

  describe "click_button/2" do
    test "works" do
      user = User.new(id: @chat_id)

      session = start_session(user)

      Api.request(nil, "sendMessage", %{
        chat_id: @chat_id,
        text: "Welcome to the bot! How are you today?",
        reply_markup: %{
          inline_keyboard: [
            [%{callback_data: "feedback", text: "Good!"}],
            [%{callback_data: "feedback", text: "So-so"}]
          ]
        }
      })

      expect(Webhook, :post_update, fn _path, update ->
        assert %{
                 "callback_query" => %{
                   "data" => "feedback",
                   "message" => %{
                     "message_id" => _,
                     "from" => %{"id" => @chat_id}
                   }
                 }
               } = update

        %{}
      end)

      session
      |> reload_session()
      |> click_button("Good")
    end

    test "raises an exception if there's no button" do
      user = User.new(id: @chat_id)

      session = start_session(user)

      Api.request(nil, "sendMessage", %{
        chat_id: @chat_id,
        text: "Welcome to the bot! How are you today?",
        reply_markup: %{
          inline_keyboard: [
            [%{callback_data: "feedback", text: "Good!"}],
            [%{callback_data: "feedback", text: "So-so"}]
          ]
        }
      })

      expect(Webhook, :post_update, fn _path, update ->
        assert %{
                 "callback_query" => %{
                   "data" => "feedback",
                   "message" => %{
                     "message_id" => _,
                     "from" => %{"id" => @chat_id}
                   }
                 }
               } = update

        %{}
      end)

      assert_raise RuntimeError, ~r/No button with text Bad found/, fn ->
        session
        |> reload_session()
        |> click_button("Bad")
      end
    end
  end
end
