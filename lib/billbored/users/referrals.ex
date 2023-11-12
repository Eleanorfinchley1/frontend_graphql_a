defmodule BillBored.Users.Referrals do
  alias BillBored.Users.Referral
  alias BillBored.User

  import Ecto.Query

  def create(params) do
    %Referral{}
    |> Referral.changeset(params)
    |> Repo.insert()
  end

  def get_user_by_referral_code(referral_code) when not is_nil(referral_code) do
    User
    |> where([u], u.referral_code == ^referral_code)
    |> Repo.one()
  end

  def list_referrers(referee_id) when is_integer(referee_id) do
    Referral
    |> where([r], r.referee_id == ^referee_id)
    |> join(:inner, [r], u in User, on: r.referrer_id == u.id and is_nil(u.event_provider) and u.banned? == false and u.deleted? == false)
    |> select([r, u], u)
    |> Repo.all()
  end

  def get_referee(referrer_id) when is_integer(referrer_id) do
    Referral
    |> where([r], r.referrer_id == ^referrer_id)
    |> join(:inner, [r], u in User, on: r.referee_id == u.id and is_nil(u.event_provider) and u.banned? == false and u.deleted? == false)
    |> select([r, u], u)
    |> limit(1)
    |> Repo.one()
  end

end
