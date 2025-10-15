defmodule Gramex.Testing.Webhook do
  import Phoenix.ConnTest

  @endpoint Application.compile_env(:gramex, :endpoint)

  def post_update(path, update) do
    build_conn()
    |> post(path, update)
    # |> tap(fn conn -> conn.resp_body end)
    |> json_response(200)
  end
end
