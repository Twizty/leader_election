defmodule LeaderElection.CandidatesContainer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: CandidatesContainer)
  end

  def init(opts) do
    {:ok, opts}
  end

  def handle_call(:get_candidates, _from, state) do
    { :reply, state, state }
  end

  def handle_call({:remove_candidate, name}, _from, state) do
    new_state = Enum.filter(state, fn {c, _} -> c != name end)
    { :reply, new_state, new_state }
  end

  def handle_call({:add_candidate, candidate}, _from, state) do
    new_state = state ++ [candidate]
    { :reply, new_state, new_state }
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end