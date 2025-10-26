defmodule Gramex.UserDataPersistencePlugTest do
  use ExUnit.Case, async: true

  import Mimic
  import Plug.Conn
  import Plug.Test

  alias Gramex.MockRepo
  alias Gramex.MockUser
  alias Gramex.UserDataPersistencePlug

  setup :set_mimic_global
  setup :verify_on_exit!

  describe "call/2" do
    test "creates new user when user doesn't exist" do
      telegram_user_data = %{
        "id" => 12345,
        "username" => "testuser",
        "is_bot" => false,
        "first_name" => "Test",
        "last_name" => "User",
        "language_code" => "en",
        "is_premium" => true
      }

      conn =
        conn(:get, "/")
        |> assign(:telegram_user_data, telegram_user_data)

      opts = [
        repo: MockRepo,
        schema: MockUser,
        changeset: :changeset
      ]

      expect(MockUser, :changeset, fn _user, attrs ->
        assert %{
                 telegram_id: 12345,
                 telegram_username: "testuser",
                 telegram_is_bot: false,
                 telegram_first_name: "Test",
                 telegram_last_name: "User",
                 telegram_language_code: "en",
                 telegram_is_premium: true,
                 updated_at: _dt,
                 telegram_last_message: _
               } = attrs

        %{}
      end)

      expect(MockRepo, :insert!, fn _changeset, opts ->
        assert opts[:returning] == true
        %{id: 123}
      end)

      conn = UserDataPersistencePlug.call(conn, opts)

      assert conn.assigns.current_user.id == 123
    end

    test "updates existing user when user exists" do
      telegram_user_data = %{
        "id" => 12345,
        "username" => "updateduser",
        "is_bot" => false,
        "first_name" => "Updated",
        "last_name" => "Name",
        "language_code" => "fr",
        "is_premium" => false
      }

      conn =
        conn(:get, "/")
        |> assign(:telegram_user_data, telegram_user_data)

      opts = [
        repo: MockRepo,
        schema: MockUser,
        changeset: :changeset
      ]

      expect(MockUser, :changeset, fn _user, attrs ->
        assert %{
                 telegram_id: 12345,
                 telegram_username: "updateduser",
                 telegram_is_bot: false,
                 telegram_first_name: "Updated",
                 telegram_last_name: "Name",
                 telegram_language_code: "fr",
                 telegram_is_premium: false,
                 updated_at: _dt,
                 telegram_last_message: _
               } = attrs

        %{}
      end)

      MockRepo
      |> expect(:get_by, fn MockUser, clauses ->
        assert clauses == [telegram_id: 12345]

        %MockUser{
          id: 456,
          telegram_id: 12345,
          telegram_username: "olduser",
          telegram_is_bot: false,
          telegram_first_name: "Old",
          telegram_last_name: "User",
          telegram_language_code: "en",
          telegram_is_premium: true
        }
      end)
      |> expect(:update!, fn _changeset, opts ->
        assert opts[:returning] == true

        %MockUser{
          id: 456,
          telegram_id: 12345,
          telegram_username: "updateduser",
          telegram_is_bot: false,
          telegram_first_name: "Updated",
          telegram_last_name: "Name",
          telegram_language_code: "fr",
          telegram_is_premium: false
        }
      end)

      result_conn = UserDataPersistencePlug.call(conn, opts)

      assert result_conn.assigns.current_user.id == 456
    end

    test "includes last_message when present" do
      telegram_user_data = %{
        "id" => 12345,
        "username" => "testuser",
        "is_bot" => false,
        "first_name" => "Test",
        "last_message" => "Hello world"
      }

      conn =
        conn(:get, "/")
        |> assign(:telegram_user_data, telegram_user_data)

      opts = [
        repo: MockRepo,
        schema: MockUser,
        changeset: :changeset
      ]

      expect(MockUser, :changeset, fn _user, attrs ->
        assert attrs.telegram_last_message == "Hello world"

        %{}
      end)

      expect(MockRepo, :insert!, fn _changeset, _opts -> %{} end)

      UserDataPersistencePlug.call(conn, opts)
    end

    test "uses custom user_assigns_key when provided" do
      telegram_user_data = %{
        "id" => 12345,
        "username" => "testuser",
        "is_bot" => false,
        "first_name" => "Test"
      }

      conn =
        conn(:get, "/")
        |> assign(:telegram_user_data, telegram_user_data)

      opts = [
        repo: MockRepo,
        schema: MockUser,
        changeset: :changeset,
        user_assigns_key: :my_custom_user
      ]

      expect(MockRepo, :insert!, fn _changeset, _opts -> %{id: 123} end)

      result_conn = UserDataPersistencePlug.call(conn, opts)

      assert result_conn.assigns.my_custom_user.id == 123
      refute Map.has_key?(result_conn.assigns, :current_user)
    end
  end
end
