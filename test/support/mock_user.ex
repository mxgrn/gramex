defmodule Gramex.MockUser do
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

    def changeset(_user, _attrs) do
      %{}
    end
end
