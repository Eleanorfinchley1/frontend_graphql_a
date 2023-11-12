defmodule BillBored.UserPointRequests do
  @moduledoc ""
  import Ecto.Query

  alias BillBored.UserPointRequest
  alias BillBored.UserPointRequest.Donation

  @spec create(BillBored.attrs(), user_id: pos_integer) ::
    {:ok, UserPointRequest.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, user_id: user_id) do
    %UserPointRequest{user_id: user_id}
    |> UserPointRequest.changeset(attrs)
    |> Repo.insert()
  end

  def get(request_id) do
    UserPointRequest
    |> preload([:donations])
    |> Repo.get(request_id)
  end

  @spec create_donation(BillBored.attrs(), receiver_id: pos_integer, sender_id: pos_integer) ::
    {:ok, Donation.t()} | {:error, Ecto.Changeset.t()}
  def create_donation(attrs, receiver_id: receiver_id, sender_id: sender_id) do
    %Donation{receiver_id: receiver_id, sender_id: sender_id}
    |> Donation.changeset(attrs)
    |> Repo.insert()
  end
end
