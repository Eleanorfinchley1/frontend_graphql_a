defmodule Web.SpeakerReactionView do
  use Web, :view

  alias BillBored.Chat.Room.DropchatStreams

  def render("show.json", %{speaker_id: user_id}) do
    reactions = DropchatStreams.speaker_reactions(user_id)
    render("show.json", %{speaker_reactions: reactions})
  end

  def render("show.json", %{speaker_reactions: reactions}) do
    reactions
    |> Enum.reduce(
      %{"clapping" => 0},
      fn reaction, result ->
        Map.put(result, reaction.type, reaction.count)
      end
    )
  end
end
