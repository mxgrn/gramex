defmodule Gramex.UpdatesTest do
  use ExUnit.Case, async: true

  alias Gramex.Updates

  describe "extract_user_data/1" do
    test "doesn't crash for channel post" do
      update = %{
        "channel_post" => %{
          "audio" => %{
            "duration" => 1,
            "file_id" =>
              "CQACAgQAAxkDAAJzFWjlB9OUC4s_pIHVYKS-ieK3sHoiAAI4CQACB9MtU4WkBGdJkGgeNgQ",
            "file_name" => "γειά.mp3",
            "file_size" => 21120,
            "file_unique_id" => "AgADOAkAAgfTLVM",
            "mime_type" => "audio/mpeg"
          },
          "author_signature" => "[Filtered]",
          "caption" => "Some caption",
          "chat" => %{
            "id" => -1_003_191_355_926,
            "title" => "Я изучаю греческий",
            "type" => "channel",
            "username" => "someusername"
          },
          "date" => 1_759_840_345,
          "message_id" => 9,
          "sender_chat" => %{
            "id" => -1_003_191_355_926,
            "title" => "Я изучаю греческий",
            "type" => "channel",
            "username" => "someusername"
          }
        },
        "update_id" => 420_823_383
      }

      assert Updates.extract_user_data(update) == nil
    end
  end

  describe "extract_chat_data/1" do
    test "works for Message" do
      result = %{
        "chat" => %{
          "first_name" => "Max",
          "id" => 2_144_377,
          "last_name" => "Gorin",
          "type" => "private",
          "username" => "mxgrn"
        },
        "date" => 1_767_146_783,
        "from" => %{
          "first_name" => "Gramex Parrot",
          "id" => 7_747_014_277,
          "is_bot" => true,
          "username" => "gramex_parrot_bot"
        },
        "message_id" => 69,
        "text" => "received: hi"
      }

      assert Updates.extract_chat_data(result) == %{
               "first_name" => "Max",
               "id" => 2_144_377,
               "last_name" => "Gorin",
               "type" => "private",
               "username" => "mxgrn"
             }
    end

    test "works for Update with Message" do
      result = %{
        "update_id" => 123,
        "message" => %{
          "chat" => %{
            "first_name" => "Max",
            "id" => 2_144_377,
            "last_name" => "Gorin",
            "type" => "private",
            "username" => "mxgrn"
          },
          "date" => 1_767_146_783,
          "from" => %{
            "first_name" => "Gramex Parrot",
            "id" => 7_747_014_277,
            "is_bot" => true,
            "username" => "gramex_parrot_bot"
          },
          "message_id" => 69,
          "text" => "received: hi"
        }
      }

      assert Updates.extract_chat_data(result) == %{
               "first_name" => "Max",
               "id" => 2_144_377,
               "last_name" => "Gorin",
               "type" => "private",
               "username" => "mxgrn"
             }
    end
  end
end
