defmodule Gramex.UserDataPersistencePlugTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn
  import Mimic

  alias Gramex.UserDataPersistencePlug
  alias Gramex.MockRepo

  defmodule TestUser do
    defstruct [
      :id,
      :telegram_id,
      :telegram_username,
      :telegram_is_bot,
      :telegram_first_name,
      :telegram_last_name,
      :telegram_language_code,
      :telegram_is_premium,
      :telegram_last_message,
      :updated_at
    ]

    def changeset(user, attrs) do
      user
      |> Map.merge(Map.new(attrs))
    end
  end

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
        schema: TestUser,
        changeset: :changeset
      ]

      expect(MockRepo, :insert!, fn user, opts ->
        assert user.telegram_id == 12345
        assert user.telegram_username == "testuser"
        assert user.telegram_is_bot == false
        assert user.telegram_first_name == "Test"
        assert user.telegram_last_name == "User"
        assert user.telegram_language_code == "en"
        assert user.telegram_is_premium == true
        assert opts[:on_conflict] == {:replace, [:telegram_username, :telegram_is_bot, :telegram_first_name, :telegram_last_name, :telegram_language_code, :telegram_is_premium, :telegram_last_message, :updated_at]}
        assert opts[:conflict_target] == :telegram_id
        assert opts[:returning] == true
        %{user | id: 123}
      end)

      result_conn = UserDataPersistencePlug.call(conn, opts)

      assert result_conn.assigns.current_user.id == 123
      assert result_conn.assigns.current_user.telegram_id == 12345
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
        schema: TestUser,
        changeset: :changeset
      ]

      expect(MockRepo, :insert!, fn user, opts ->
        assert user.telegram_username == "updateduser"
        assert user.telegram_first_name == "Updated"
        assert opts[:on_conflict] == {:replace, [:telegram_username, :telegram_is_bot, :telegram_first_name, :telegram_last_name, :telegram_language_code, :telegram_is_premium, :telegram_last_message, :updated_at]}
        assert opts[:conflict_target] == :telegram_id
        %{user | id: 999}
      end)

      result_conn = UserDataPersistencePlug.call(conn, opts)

      assert result_conn.assigns.current_user.id == 999
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
        schema: TestUser,
        changeset: :changeset
      ]

      expect(MockRepo, :insert!, fn user, _opts ->
        assert user.telegram_last_message == "Hello world"
        %{user | id: 123}
      end)

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
        schema: TestUser,
        changeset: :changeset,
        user_assigns_key: :my_custom_user
      ]

      expect(MockRepo, :insert!, fn user, _opts -> %{user | id: 123} end)

      result_conn = UserDataPersistencePlug.call(conn, opts)

      assert result_conn.assigns.my_custom_user.id == 123
      refute Map.has_key?(result_conn.assigns, :current_user)
    end
  end
end
