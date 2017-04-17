defmodule LeaderElection.CandidatesContanerTest do
  use ExUnit.Case

  test "inits with empty array" do
    LeaderElection.CandidatesContainer.start_link

    state = GenServer.call(CandidatesContainer, :get_candidates)
    assert [] == state
  end

  test "adds candidate with given name" do
    LeaderElection.CandidatesContainer.start_link

    GenServer.call(CandidatesContainer, {:add_candidate, {:foo, 1}})
    state = GenServer.call(CandidatesContainer, :get_candidates)
    assert [foo: 1] == state
  end

  test "removes candidate by given name" do
    LeaderElection.CandidatesContainer.start_link

    GenServer.call(CandidatesContainer, {:add_candidate, {:foo, 1}})
    GenServer.call(CandidatesContainer, {:add_candidate, {:bar, 2}})
    state = GenServer.call(CandidatesContainer, :get_candidates)
    assert [foo: 1, bar: 2] == state

    GenServer.call(CandidatesContainer, {:remove_candidate, :bar})
    state = GenServer.call(CandidatesContainer, :get_candidates)
    assert [foo: 1] == state
  end
end