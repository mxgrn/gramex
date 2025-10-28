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

  describe "assert_text/2" do
    test "passes when text contains string" do
      user = User.new(id: @chat_id)

      session = start_session(user)

      Api.request(nil, "sendMessage", %{
        chat_id: @chat_id,
        text: "Welcome to the bot! How are you today?"
      })

      session
      |> reload_session()
      |> assert_text("Welcome")
      |> assert_text("How are you")
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
      |> assert_text(~r/code is: \d+/)
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
        |> assert_text("Goodbye")
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
        |> assert_text(~r/^\d+$/)
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

      assert_raise RuntimeError, ~r/No button with text 'Bad' found/, fn ->
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

      assert_raise RuntimeError, ~r/No button with text 'Bad' found/, fn ->
        session
        |> reload_session()
        |> click_button("Bad")
      end
    end
  end

  describe "assert_voice/2" do
    test "passes when voice message with caption exists" do
      user = User.new(id: @chat_id)

      session = start_session(user)

      Api.request(nil, "sendVoice", %{
        chat_id: @chat_id,
        voice: %{
          file_id: "AwACAgQAAxkDAAJzFWjlB9OUC4s_pIHVYKS-ieK3sHoiAAI4CQACB9MtU4WkBGdJkGgeNgQ",
          duration: 5
        },
        caption: "Here is your voice message"
      })

      session
      |> reload_session()
      |> assert_voice("your voice message")
    end
  end

  describe "assert_invoice/2" do
    test "passes when invoice message with title exists" do
      user = User.new(id: @chat_id)

      session = start_session(user)

      Api.request(nil, "sendInvoice", %{
        chat_id: @chat_id,
        title: "Premium Subscription",
        description: "Access to all features",
        payload: "payload_123",
        provider_token: "provider_token_abc",
        currency: "USD",
        prices: [%{label: "Subscription", amount: 999}]
      })

      session
      |> reload_session()
      |> assert_invoice("Premium Subscription")
    end
  end
end
