defmodule LeaderElection.NodeTest do
  use ExUnit.Case

  test "starts king" do
    LeaderElection.KingContainer.start_link
    LeaderElection.CandidatesContainer.start_link

    pid = LeaderElection.Node.start_king
    state = GenServer.call(KingContainer, :get)
    assert pid == state
  end

  test "starts candidate" do
    LeaderElection.KingContainer.start_link
    LeaderElection.CandidatesContainer.start_link

    pid = LeaderElection.Node.start_king
    c1_pid = LeaderElection.Node.start_candidate(:c1, 1000, pid)
    candidates = GenServer.call(CandidatesContainer, :get_candidates)
    assert candidates == [c1: c1_pid]

    c2_pid = LeaderElection.Node.start_candidate(:c2, 1000, pid)
    candidates = GenServer.call(CandidatesContainer, :get_candidates)
    assert candidates == [c1: c1_pid, c2: c2_pid]
  end

  test "first process becomes king if king is dead" do
    LeaderElection.KingContainer.start_link
    LeaderElection.CandidatesContainer.start_link

    pid = LeaderElection.Node.start_king
    c_pid = LeaderElection.Node.start_candidate(:c, 10, pid)

    GenServer.call(KingContainer, :unset_king)
    assert Process.info(pid) == nil

    :timer.sleep(70)
    {_, func, _} = Process.info(c_pid)[:current_function]
    assert func == :king
  end

  test "alive king responses that he's ok" do
    LeaderElection.KingContainer.start_link
    LeaderElection.CandidatesContainer.start_link

    pid = LeaderElection.Node.start_king

    send pid, { :ping, self() }
    receive do
      { :imokay, ^pid } -> assert true
      _ -> assert false
    end
  end

  test "updates king on :imtheking" do
    LeaderElection.KingContainer.start_link
    LeaderElection.CandidatesContainer.start_link

    pid = LeaderElection.Node.start_king
    c1_pid = LeaderElection.Node.start_candidate(:c1, 10, pid)
    GenServer.call(KingContainer, :unset_king)
    :timer.sleep(15)
    send c1_pid, { :imtheking, self() }
    receive do
      { :ping, ^c1_pid } -> assert true
      _ -> assert false
    after 15 -> assert false
    end
  end

  test "becomes elector when gets :alive?" do
    LeaderElection.KingContainer.start_link
    LeaderElection.CandidatesContainer.start_link

    pid = LeaderElection.Node.start_king
    c1_pid = LeaderElection.Node.start_candidate(:c1, 10, pid)
    c2_pid = LeaderElection.Node.start_candidate(:c2, 10, pid)
    GenServer.call(KingContainer, :unset_king)
    Process.exit(c1_pid, :reason)
    :timer.sleep(70)
    {_, func, _} = Process.info(c2_pid)[:current_function]
    assert func == :elector
  end

  # These tests may fail sometimes but it'll be improved later.
  test "becomes almost king when gets :finethanks" do
    LeaderElection.KingContainer.start_link
    LeaderElection.CandidatesContainer.start_link

    pid = LeaderElection.Node.start_king
    c1_pid = LeaderElection.Node.start_candidate(:c1, 10, pid)
    Process.exit(c1_pid, :reason)
    GenServer.call(KingContainer, :unset_king)
    c2_pid = LeaderElection.Node.start_candidate(:c2, 100, pid)
    :timer.sleep(10)
    c3_pid = LeaderElection.Node.start_candidate(:c3, 10, pid)
    :timer.sleep(58)
    IO.inspect Process.info(c2_pid)
    {_, c2_func, _} = Process.info(c2_pid)[:current_function]
    assert c2_func == :elector
    Process.exit(c2_pid, :reason)
    {_, func, _} = Process.info(c3_pid)[:current_function]
    assert func == :almost_king
  end

  test "almost king becomes candidate when gets :imtheking" do
    LeaderElection.KingContainer.start_link
    LeaderElection.CandidatesContainer.start_link

    f = fn ->
      receive do
        _ -> :ok
      end
    end

    p = spawn(fn -> f.() end)

    pid = LeaderElection.Node.start_king
    c1_pid = LeaderElection.Node.start_candidate(:c1, 10, pid)
    Process.exit(c1_pid, :reason)
    GenServer.call(KingContainer, :unset_king)
    c2_pid = LeaderElection.Node.start_candidate(:c2, 100, pid)
    :timer.sleep(10)
    c3_pid = LeaderElection.Node.start_candidate(:c3, 10, pid)
    :timer.sleep(58)
    IO.inspect Process.info(c2_pid)
    {_, c2_func, _} = Process.info(c2_pid)[:current_function]
    assert c2_func == :elector
    Process.exit(c2_pid, :reason)
    {_, func, _} = Process.info(c3_pid)[:current_function]
    assert func == :almost_king

    send c3_pid, { :imtheking, p }
    :timer.sleep(5)
    {_, func, _} = Process.info(c3_pid)[:current_function]
    assert func == :candidate
  end

  test "becomes candidate when gets error at setting yourself king" do
    LeaderElection.KingContainer.start_link
    LeaderElection.CandidatesContainer.start_link

    f = fn ->
      receive do
        _ -> :ok
      end
    end

    p = spawn(fn -> f.() end)

    pid = LeaderElection.Node.start_king
    c1_pid = LeaderElection.Node.start_candidate(:c1, 10, pid)
    c2_pid = LeaderElection.Node.start_candidate(:c2, 10, pid)
    GenServer.call(KingContainer, :unset_king)
    Process.exit(c1_pid, :reason)
    :timer.sleep(70)
    {_, func, _} = Process.info(c2_pid)[:current_function]
    assert func == :elector

    send c2_pid, { :imtheking, p }
    :timer.sleep(9)

    {_, func, _} = Process.info(c2_pid)[:current_function]
    assert func == :candidate
  end
end
