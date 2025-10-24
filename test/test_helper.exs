ExUnit.start()

Mimic.copy(Gramex.Testing.Webhook)
Mimic.copy(Gramex.MockRepo)

Application.put_env(:gramex, :adapter, Gramex.ApiMock)
