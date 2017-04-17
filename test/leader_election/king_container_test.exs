defmodule LeaderElection.KingContainerTest do
  use ExUnit.Case

  test "starts with nil" do
    LeaderElection.KingContainer.start_link

    state = GenServer.call(KingContainer, :get)
    assert state == nil
  end

  test "sets king if king is nil" do
    LeaderElection.KingContainer.start_link

    GenServer.call(KingContainer, {:set_king, 1})
    state = GenServer.call(KingContainer, :get)
    assert state == 1
  end

  test "refuces to set king if king is not nil" do
    LeaderElection.KingContainer.start_link

    GenServer.call(KingContainer, {:set_king, 1})
    state = GenServer.call(KingContainer, :get)
    assert state == 1

    assert GenServer.call(KingContainer, {:set_king, 2}) == {:error, 1}
  end

  test "kills process when unsets king" do
    LeaderElection.KingContainer.start_link

    f = fn ->
      receive do
        _ -> :ok
      end
    end

    p = spawn(fn -> f.() end)

    GenServer.call(KingContainer, {:set_king, p})
    assert Process.info(p) != nil
    GenServer.call(KingContainer, :unset_king)
    assert Process.info(p) == nil
  end
end