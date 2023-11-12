defmodule BillBored.Chat.Room.Memberships do
  @moduledoc ""

  alias BillBored.{Chat, User}

  @spec get_by(Keyword.t()) :: Chat.Room.Membership.t() | nil
  def get_by(user_id: user_id, room_key: room_key) do
    import Ecto.Query

    Chat.Room.Membership
    |> where(userprofile_id: ^user_id)
    |> join(:inner, [m], r in Chat.Room, on: m.room_id == r.id)
    |> where([m, r], r.key == ^room_key)
    |> select([m, r], %{m | room: r})
    |> Repo.one()
  end

  def get_by(user_id: user_id, room_id: room_id) do
    Repo.get_by(Chat.Room.Membership, userprofile_id: user_id, room_id: room_id)
  end

  @spec create!(user_id: pos_integer, room_id: pos_integer) ::
          Chat.Room.Membership.t() | no_return
  def create!(user_id: user_id, room_id: room_id) do
    Repo.insert!(%Chat.Room.Membership{userprofile_id: user_id, room_id: room_id})
  end

  @spec create!(User.t(), Chat.Room.t()) :: Chat.Room.Membership.t() | no_return
  def create!(%User{id: user_id}, %Chat.Room{id: room_id}) do
    Repo.insert!(%Chat.Room.Membership{userprofile_id: user_id, room_id: room_id})
  end

  def create(user_or_id, room_or_id, role \\ "member")

  def create(%User{id: user_id}, %Chat.Room{id: room_id}, role) do
    create(user_id, room_id, role)
  end

  def create(user_id, room_id, role) do
    Chat.Room.Membership.changeset(%Chat.Room.Membership{}, %{userprofile_id: user_id, room_id: room_id, role: role})
    |> Repo.insert(conflict_target: [:userprofile_id, :room_id], on_conflict: {:replace, [:role]})
  end
end
