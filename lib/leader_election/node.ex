defmodule LeaderElection.Node do
  def start_candidate(name, t, king) do
    pid = spawn(__MODULE__, :candidate, [name, t, 0, king])
    GenServer.call(CandidatesContainer, {:add_candidate, {name, pid}})
    pid
  end

  def start_king() do
    pid = spawn(__MODULE__, :king, [])
    GenServer.call(KingContainer, {:set_king, pid })
    pid
  end

  def candidate(name, t, count, king) do
    :c.flush()
    send king, { :ping, self() }

    receive do
      { :imtheking, new_king } ->
        :timer.sleep(t)
        candidate(name, t, 0, new_king)
      { :imokay, ^king } ->
        :timer.sleep(t)
        candidate(name, t, 0, king)
      { :alive?, sender } ->
        if name == :c2, do: IO.puts("!!!")
        send(sender, { :finethanks, self() })
        elector(name, t)
    after
      t ->
        if count < 4 do
          candidate(name, t, count + 1, king)
        else
          elector(name, t)
        end
    end
  end

  def king() do
    receive do
      { :ping, sender } ->
        send sender, {:imokay, self()}
        king()
    end
  end

  def elector(name, t) do
    IO.puts "#{name} starts election"
    candidates = GenServer.call(CandidatesContainer, :get_candidates)
    elder_candidates = Enum.take_while(candidates, fn {c, _} -> c != name end)

    if (length(elder_candidates) == 0) do
      become_king(name, candidates, t)
    else
      Enum.each(elder_candidates, fn {_, p} -> send(p, {:alive?, self()}) end)
      receive do
        { :imtheking, new_king } -> candidate(name, t, 0, new_king)
        { :finethanks, _ } -> almost_king(name, t)
      after
        t -> become_king(name, candidates, t)
      end
    end
  end

  def almost_king(name, t) do
    receive do
      { :imtheking, new_king } -> candidate(name, t, 0, new_king)
    after
      t ->
        candidates = GenServer.call(CandidatesContainer, :get_candidates)
        become_king(name, candidates, t)
    end
  end

  def become_king(name, candidates, t) do
    case GenServer.call(KingContainer, {:set_king, self()}) do
      { :error, king_pid } -> candidate(name, t, 0, king_pid)
      :ok ->
        GenServer.call(CandidatesContainer, {:remove_candidate, name})
        Enum.each(candidates, fn {c, p} -> if c != name, do: send(p, {:imtheking, self()}) end)
        IO.puts "#{name} becomes king"
        king()
    end
  end
end