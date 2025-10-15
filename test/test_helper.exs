ExUnit.start()

Mimic.copy(Gramex.Testing.Webhook)

Application.put_env(:gramex, :adapter, Gramex.ApiMock)
