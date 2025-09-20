defmodule Gramex.Api do
  def request(token, method, params \\ %{}) do
    adapter = Application.get_env(:gramex, :adapter) || Gramex.ApiReq
    adapter.request(token, method, params)
  end
end
