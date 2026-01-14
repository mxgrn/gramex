defmodule Gramex.Api do
  def request(token, method, params \\ %{}, opts \\ []) do
    adapter = Application.get_env(:gramex, :adapter) || Gramex.ApiReq
    adapter.request(token, method, params, opts)
  end
end
