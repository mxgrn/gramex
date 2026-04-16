defmodule Gramex.MiniappAuthPlugTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias Gramex.MiniappAuthPlug

  @token "test_bot_token_123"

  defp sign_params(params, token) do
    data_check_string =
      params
      |> Enum.sort(fn {k1, _}, {k2, _} -> k1 <= k2 end)
      |> Enum.map_join("\n", fn {k, v} -> "#{k}=#{v}" end)

    hash =
      :crypto.mac(:hmac, :sha256, "WebAppData", token)
      |> then(&:crypto.mac(:hmac, :sha256, &1, data_check_string))
      |> Base.encode16(case: :lower)

    Map.put(params, "hash", hash)
  end

  defp build_conn(params) do
    conn(:get, "/", params)
    |> Plug.Test.init_test_session(%{})
    |> fetch_query_params()
  end

  test "authenticates with valid hash and sets session" do
    user = JSON.encode!(%{"id" => 42, "first_name" => "Test"})

    params =
      %{"user" => user, "auth_date" => "1700000000"}
      |> sign_params(@token)

    conn = build_conn(params) |> MiniappAuthPlug.call(token: @token)

    assert get_session(conn, "telegram_user_id") == 42
    assert get_session(conn, "start_param") == nil
    refute conn.halted
  end

  test "returns 401 with invalid hash" do
    user = JSON.encode!(%{"id" => 42, "first_name" => "Test"})

    params = %{"user" => user, "auth_date" => "1700000000", "hash" => "badhash"}

    conn = build_conn(params) |> MiniappAuthPlug.call(token: @token)

    assert conn.status == 401
    assert conn.halted
  end

  test "accepts token as a function" do
    user = JSON.encode!(%{"id" => 42, "first_name" => "Test"})

    params =
      %{"user" => user, "auth_date" => "1700000000"}
      |> sign_params(@token)

    conn = build_conn(params) |> MiniappAuthPlug.call(token: fn -> @token end)

    assert get_session(conn, "telegram_user_id") == 42
    refute conn.halted
  end

  test "passes through when no hash param" do
    conn = build_conn(%{"foo" => "bar"}) |> MiniappAuthPlug.call(token: @token)

    refute conn.halted
    assert conn.status == nil
  end

  test "redirects when start_param contains path" do
    start_param = %{"path" => "/dashboard"} |> JSON.encode!() |> Base.url_encode64()
    user = JSON.encode!(%{"id" => 42, "first_name" => "Test"})

    params =
      %{"user" => user, "auth_date" => "1700000000", "start_param" => start_param}
      |> sign_params(@token)

    conn = build_conn(params) |> MiniappAuthPlug.call(token: @token)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/dashboard"]
    assert get_session(conn, "telegram_user_id") == 42
  end
end
