defmodule BillBored.Version do
  @moduledoc false

  {sha, 128} = System.cmd("git", ["rev-parse", "HEAD"])
  sha = String.trim(sha)

  @spec commit_sha :: String.t()
  def commit_sha do
    unquote(sha)
  end
end
