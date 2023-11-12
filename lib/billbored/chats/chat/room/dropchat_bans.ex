defmodule BillBored.Chat.Room.DropchatBans do
  import Ecto.Query

  alias BillBored.User
  alias BillBored.Chat.Room
  alias BillBored.Chat.Room.DropchatBan

  def create(%Room{} = room, %User{} = admin, %User{} = banned_user) do
    result =
      %DropchatBan{}
      |> DropchatBan.changeset(%{dropchat: room, admin: admin, banned_user: banned_user})
      |> Repo.insert(on_conflict: :nothing, conflict_target: [:dropchat_id, :banned_user_id])

    with {:ok, _} <- result do
      Phoenix.PubSub.broadcast(Web.PubSub, "user:#{banned_user.id}:dropchat", {:dropchat_ban, %{user: banned_user, room: room}})
      result
    end
  end

  def exists?(%Room{id: room_id}, %User{id: user_id}) do
    from(b in DropchatBan, where: b.dropchat_id == ^room_id and b.banned_user_id == ^user_id)
    |> Repo.exists?()
  end
end
