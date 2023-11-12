defmodule BillBored.AnticipationCandidates do
  @moduledoc ""
  import Ecto.Query

  alias BillBored.AnticipationCandidate

  def create(attr) do
    %AnticipationCandidate{}
    |> AnticipationCandidate.changeset(attr)
    |> Repo.insert()
  end

  def candidate_user(user_id, topic, now \\ DateTime.utc_now()) do
    AnticipationCandidate
    |> where(user_id: ^user_id)
    |> where(topic: ^topic)
    |> where(rewarded: false)
    |> where([ac], ac.expire_at >= ^now)
    |> limit(1)
    |> Repo.one()
  end

  def update(candidate, attrs) do
    candidate
    |> AnticipationCandidate.changeset(attrs)
    |> Repo.update()
  end
end
