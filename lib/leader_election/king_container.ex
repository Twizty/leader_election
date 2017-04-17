defmodule LeaderElection.KingContainer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: KingContainer)
  end

  def init([]) do
    {:ok, nil}
  end

  def handle_call({:set_king, king_pid}, _from, nil) do
    { :reply, :ok, king_pid }
  end

  def handle_call({:set_king, _}, _from, state) when state != nil do
    { :reply, { :error, state }, state }
  end

  def handle_call(:unset_king, _form, king_pid) do
    Process.exit(king_pid, :death)
    { :reply, :ok, nil }
  end

  def handle_call(_msg, _from, state) do
    {:reply, state, state}
  end
end