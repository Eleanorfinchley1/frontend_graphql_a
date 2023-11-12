defmodule Web.ChatView do
  use Web, :view

  def render("chat_search.json", %{rooms: rooms}) do
    # render_many(rooms, __MODULE__, "room.json")
    render_many(rooms, __MODULE__, "chat_search_room_response.json")
  end

  def render("chat_search_room_response.json", %{chat: room}) do
    %{"key" => room.key}
  end

  def render("index.json", %{rooms: rooms}) do
    render_many(rooms, __MODULE__, "show.json")
  end

  def render("show.json", %{chat: room}) do
    room
    |> Map.take([
      :id,
      :key,
      :title,
      :private,
      :last_interaction,
      :last_message,
      :created,
      :chat_type
    ])
    |> Map.put(:users, render_many(room.members, Web.UserView, "user.json"))
    |> Map.put(:administrators, render_many(room.administrators, Web.UserView, "user.json"))
    |> Map.put(:location, render_one(room.location, Web.LocationView, "show.json"))
    |> Map.put(:interests, render_many(room.interests, Web.InterestView, "show.json"))
    |> Map.put(:pending, render_many(room.pending, Web.UserView, "user.json"))
    |> Map.put(:place, render_one(room.place, Web.PlaceView, "show.json"))
    |> Map.put(
      :reach_area_radius,
      room.reach_area_radius && Decimal.to_float(room.reach_area_radius)
    )
  end

  def render("room.json", %{chat: room}) do
    render("show.json", %{chat: room})
  end
end
