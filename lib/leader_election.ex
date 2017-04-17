defmodule LeaderElection do
  use Application

  def start(_type, _args) do
    LeaderElection.CandidatesContainer.start_link
    IO.puts("Please start KingContainer manually with `LeaderElection.KingContainer.start_link`")
    IO.puts("And then spawn candidates, crash king, and watch election")
    IO.puts("For examples please check tests")
    { :ok, self() }
  end
end
