defmodule Gramex.ApiMockTest do
  use Gramex.Case

  alias Gramex.Api
  alias Gramex.Testing.Sessions.User

  @chat_id 123_456

  test "setMessageReaction" do
    user = User.new(id: @chat_id)

    session = start_session(user)

    Api.request(nil, "setMessageReaction", %{
      chat_id: @chat_id,
      reaction: [%{type: "emoji", emoji: "👍"}]
    })

    session
    |> reload_session()
    |> assert_method("setMessageReaction")
  end

  test "request" do
    user = User.new(id: @chat_id)

    session = start_session(user)

    Api.request(nil, "sendMessage", %{
      chat_id: @chat_id,
      text: "Hello"
    })

    %{updates: [update]} = reload_session(session)
    assert update.response["from"]["username"] == "testbot"
    assert update.response["from"]["is_bot"]
  end
end
