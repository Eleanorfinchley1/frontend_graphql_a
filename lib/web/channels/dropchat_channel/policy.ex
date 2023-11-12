defmodule Web.DropchatChannel.Policy do
  import Ecto.Query

  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.Chat.Rooms
  alias BillBored.Chat.Room.Membership

  @moderator_actions ~w(add_stream_speaker remove_stream_speaker)a

  def authorize(action, actor_id, %DropchatStream{admin_id: admin_id, dropchat_id: dropchat_id}, speaker_id) when action in @moderator_actions do
    cond do
      Rooms.admin?(room_id: dropchat_id, user_id: actor_id) ->
        true

      has_membership_role?(dropchat_id, actor_id, "moderator") ->
        if admin_id == speaker_id do
          {false, :insufficient_privileges}
        else
          true
        end

      true ->
        {false, :insufficient_privileges}
    end
  end

  defp has_membership_role?(room_id, user_id, role) do
    from(m in Membership,
      where: m.room_id == ^room_id and
        m.userprofile_id == ^user_id and
          m.role == ^role
    )
    |> Repo.exists?()
  end
end
