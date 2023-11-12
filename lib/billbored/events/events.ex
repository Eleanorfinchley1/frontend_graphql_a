defmodule BillBored.Events do
  import Ecto.Query
  import Ecto.Changeset

  alias BillBored.{Event, User, Interest}
  alias Event.Attendant

  alias Ecto.Multi

  def get(id, opts \\ []) do
    user_id = opts[:for_id] || (opts[:for] && opts[:for].id)

    event =
      Event
      |> preload(:media_files)
      |> where(id: ^id)
      |> Repo.one()

    if event do
      add_statistics(event, for_id: user_id || -1)
    end
  end

  def get!(id, opts \\ []) do
    user_id = opts[:for_id] || (opts[:for] && opts[:for].id)

    Event
    |> preload(:media_files)
    |> where(id: ^id)
    |> Repo.one!()
    |> add_statistics(for_id: user_id || -1)
  end

  defp count(event_id, status) do
    Event.Attendant
    |> where(event_id: ^event_id)
    |> where(status: ^status)
    |> select([a], count(a.id))
    |> Repo.one()
  end

  def add_statistics(%{id: id} = event, for_id: user_id) do
    {:ok, stats} =
      Multi.new()
      |> Multi.run(:doubts_count, fn _repo, _changes ->
        {:ok, count(id, "doubts")}
      end)
      |> Multi.run(:presented_count, fn _repo, _changes ->
        {:ok, count(id, "presented")}
      end)
      |> Multi.run(:refused_count, fn _repo, _changes ->
        {:ok, count(id, "refused")}
      end)
      |> Multi.run(:missed_count, fn _repo, _changes ->
        {:ok, count(id, "missed")}
      end)
      |> Multi.run(:accepted_count, fn _repo, _changes ->
        {:ok, count(id, "accepted")}
      end)
      |> Multi.run(:invited_count, fn _repo, _changes ->
        {:ok, count(id, "invited")}
      end)
      |> Multi.run(:user_status, fn repo, _changes ->
        user_status =
          Event.Attendant
          |> where(user_id: ^user_id)
          |> where(event_id: ^id)
          |> select([d], d.status)
          |> repo.one()

        {:ok, user_status}
      end)
      |> Repo.transaction()

    Map.merge(event, stats)
  end

  def delete(event_id) do
    Event
    |> where(id: ^event_id)
    |> Repo.delete_all()
  end

  @all Attendant.statuses().future ++ Attendant.statuses().past

  defp set(event, for_id: user_id, to: status) do
    Attendant
    |> Repo.get_by(user_id: user_id, event_id: event.id)
    |> case do
      nil -> %Attendant{}
      att -> att
    end
    |> change(user_id: user_id, event_id: event.id, status: status)
    |> Repo.insert_or_update()
    |> case do
      {:ok, %Attendant{status: "accepted"} = attendant} = success ->
        attendant
        |> Repo.preload([:user, event: [post: [author: :devices]]])
        |> Notifications.process_event_attending()

        success

      other ->
        other
    end
  end

  def set_status(event, for_id: user_id, to: status) when status in @all do
    if DateTime.compare(DateTime.utc_now(), event.date) == :gt do
      # future event:
      if status in Attendant.statuses().past do
        {:error, :future}
      else
        set(event, for_id: user_id, to: status)
      end
    else
      if status in Attendant.statuses().future do
        set(event, for_id: user_id, to: status)
      else
        {:error, :past}
      end
    end
  end

  def set_status(_event_id, for_id: _user_id, to: _) do
    {:error, :incorrent}
  end

  def create(params) do
    Multi.new()
    |> Multi.insert(:event, Event.changeset(%Event{}, params))
    |> Multi.run(:notifications, fn repo, %{event: event} ->
      event = repo.preload(event, post: :interests)
      receivers = list_interested_nearby_users(event)
      Notifications.process_matching_event_interests(event: event, receivers: receivers)

      {:ok, nil}
    end)
    |> Multi.run(:event_with_media_files, fn repo, %{event: event} ->
      {:ok, repo.preload(event, [:media_files])}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{event_with_media_files: event}} -> {:ok, event}
      {:error, :event, changeset, _changes} -> {:error, changeset}
    end
  end

  def list_interested_nearby_users(
        %Event{location: event_location, categories: categories} = event
      ) do
    import Geo.PostGIS, only: [st_distance_in_meters: 2]
    event_interest_ids = Enum.map(event.post.interests, & &1.id)

    interested_users =
      Interest
      |> join(:inner, [i], ui in User.Interest, on: ui.interest_id == i.id)
      |> where([i, ui], ui.interest_id in ^event_interest_ids)
      |> or_where([i, ui], i.hashtag in ^categories)
      |> select([i, ui], %{user_id: ui.user_id})

    User
    |> where(
      [u],
      st_distance_in_meters(u.user_real_location, ^event_location) <
        fragment("? * 1000", u.prefered_radius)
    )
    |> join(:inner, [u], i in subquery(interested_users), on: u.id == i.user_id)
    |> preload([u], :devices)
    |> Repo.all()
  end

  def update(event, params) do
    event
    |> Event.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, event} -> {:ok, Repo.preload(event, :media_files)}
      {:error, _changeset} = error -> error
    end
  end
end
