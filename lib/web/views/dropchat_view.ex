defmodule Web.DropchatView do
  use Web, :view
  alias BillBored.Chat.Room.ElevatedPrivilege

  def render("granted_privilege.json", %{
        granted_privilege: %ElevatedPrivilege{id: granted_privilege_id}
      }) do
    %{"granted_privilege" => %{"id" => granted_privilege_id}}
  end

  def render("user_streams.json", %{entries: entries} = scrivener) do
    rendered_streams =
      Enum.map(entries, fn %{dropchat: dropchat} = stream ->
        Web.RoomView.render("dropchat_stream.json", %{
          room: dropchat,
          dropchat_stream: stream
        })
      end)

    scrivener
    |> Map.take([:page_number, :page_size, :total_pages, :total_entries])
    |> Map.put(:entries, rendered_streams)
  end
end
