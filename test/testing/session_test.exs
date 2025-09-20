defmodule Gramex.Testing.SessionTest do
  use Gramex.Case

  alias Gramex.Testing.Session
  alias Gramex.Testing.Webhook

  @chat_id 123_456

  describe "click_button/2" do
    test "works" do
      session =
        Session.new_session(
          @chat_id,
          [
            %{text: "Welcome to the bot!", chat_id: @chat_id},
            %{
              text: "Your native language is English, is that right?",
              chat_id: @chat_id,
              reply_markup: %{
                inline_keyboard: [
                  [%{callback_data: "confirm_native_language", text: "Yes!"}],
                  [
                    %{
                      callback_data: "change_language",
                      text: "No, my native language is different"
                    }
                  ]
                ]
              }
            }
          ]
        )

      expect(Webhook, :post_update, 2, fn update ->
        assert %{
                 "callback_query" => %{
                   "data" => "confirm_native_language",
                   "message" => %{
                     "from" => %{"id" => @chat_id}
                   }
                 }
               } = update

        %{}
      end)

      Session.click_button(session, "Yes")
    end
  end
end
