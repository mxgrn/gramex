ExUnit.start()

Mimic.copy(Gramex.Testing.Webhook)
Mimic.copy(Gramex.MockRepo)
Mimic.copy(Gramex.MockUser)

Application.put_env(:gramex, :adapter, Gramex.ApiMock)
