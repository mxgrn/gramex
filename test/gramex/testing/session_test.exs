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
  end
end
