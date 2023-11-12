defmodule Web.Policies.DropchatControllerPolicy do
  alias BillBored.Chat.Room.DropchatStream

  @admin_actions ~w(remove_stream_recordings)a

  def authorize(action, actor_id, %DropchatStream{admin_id: admin_id}) when action in @admin_actions do
    cond do
      admin_id == actor_id ->
        true

      true ->
        {false, :insufficient_privileges}
    end
  end
end
