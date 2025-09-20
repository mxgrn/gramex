defmodule Gramex.Testing.BotCase.Registry do
  @moduledoc """
  Keeps track of ongoing sessions (chats with bots) as identified by chat_id.
  Note: user here is a Telegram user.
  """

  use GenServer

  alias Gramex.Testing.BotCase.Session

  @doc false
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    {:ok, %{}}
  end

  def add_session(user, updates) do
    GenServer.call(__MODULE__, {:add_session, user, updates})
  end

  @impl true
  def handle_call({:add_session, user, updates}, _from, state) do
    new_state = Map.put(state, user.id, Session.new(user, updates))
    {:reply, new_state, new_state}
  end

  def handle_call({:append_to_session, chat_id, update}, _from, state) do
    session = state |> Map.get(chat_id, Session.new(chat_id))
    updates = session.updates ++ [update]
    new_session = %{session | updates: updates}

    new_state = Map.put(state, chat_id, new_session)

    {:reply, new_state, new_state}
  end

  def handle_call({:get_session, chat_id}, _from, state) do
    session = state |> Map.get(chat_id, Session.new(chat_id))
    {:reply, session, state}
  end

  @doc """
  Appends to session an update that we send to the bot API.
  """
  def append_to_session(chat_id, update) do
    GenServer.call(__MODULE__, {:append_to_session, chat_id, update})
  end

  def get_session(chat_id) do
    GenServer.call(__MODULE__, {:get_session, chat_id})
  end
end
