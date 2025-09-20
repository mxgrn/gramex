defmodule Gramex.WebhookTest do
  use ExUnit.Case, async: true

  alias Gramex.Webhook

  describe "extract_user_data/1" do
    test "works for channel post" do
      update = %{
        channel_post: %{
          audio: %{
            duration: 1,
            file_id: "CQACAgQAAxkDAAJzFWjlB9OUC4s_pIHVYKS-ieK3sHoiAAI4CQACB9MtU4WkBGdJkGgeNgQ",
            file_name: "γειά.mp3",
            file_size: 21120,
            file_unique_id: "AgADOAkAAgfTLVM",
            mime_type: "audio/mpeg"
          },
          author_signature: "[Filtered]",
          caption: "Γειά σου, πώς είσαι;",
          chat: %{
            id: -1_003_191_355_926,
            title: "「я υⳅⲩɥⲁю ⲅⲣⲉɥⲉⲥⲕυύ」",
            type: "channel",
            username: "greekfairy"
          },
          date: 1_759_840_345,
          message_id: 9,
          sender_chat: %{
            id: -1_003_191_355_926,
            title: "「я υⳅⲩɥⲁю ⲅⲣⲉɥⲉⲥⲕυύ」",
            type: "channel",
            username: "greekfairy"
          }
        },
        update_id: 420_823_383
      }

      assert Webhook.extract_user_data(update) == nil
    end
  end
end
