defmodule BillBored.Workers.GiveAnticipationPoints do
  @moduledoc """
  """
  import Ecto.Query

  require Logger

  alias BillBored.{
    User,
    University,
    UserPoints,
    Chat.Room.DropchatStream,
    Topics,
    AnticipationCandidate
  }

  @cond_percentage 10
  @cond_double_hour 1

  def call(now \\ DateTime.utc_now()) do
    created_after = DateTime.add(now, -3600)
    today_start = %{now | second: 0, minute: 0, hour: 0}

    topics = Topics.get_topics()
    # topics = %{id: 1, meta: [%{university_name: "concordia", topics: ["Food", "Sport"]}, %{university_name: "mcgillu", topics: ["Art", "Music"]}]}

    if not is_nil(topics) do

      from(un in University,
        join: u in User,
        on: un.id == u.university_id and is_nil(u.event_provider) and u.banned? == false and u.deleted? == false,
        left_join: ds in DropchatStream,
        on: u.id == ds.admin_id and (ds.status == "active" or ds.finished_at >= ^created_after),
        group_by: un.id,
        having: fragment("COUNT(DISTINCT ?) * 100", ds.id) < fragment("COUNT(DISTINCT ?) * ?", u.id, ^@cond_percentage)
      )
      |> Repo.all()
      |> Enum.each(fn university ->
        topics = topics.meta
          |> Enum.filter(fn %{university_name: university_name} ->
            case university_name do
              "mcgillu" ->
                String.downcase(university.name) == "mcgill university"
              _ ->
                String.downcase(university_name <> " university") == String.downcase(university.name)
            end
          end)
          |> Enum.reduce([], fn %{topics: topics}, all_topics -> topics ++ all_topics end)

        if length(topics) > 0 do

          topic = Enum.random(topics)

          recent_ds = from(ds in DropchatStream,
            join: u in User,
            on: ds.admin_id == u.id and u.university_id == ^university.id,
            left_join: ac in AnticipationCandidate,
            on: ds.admin_id == ac.user_id and ac.inserted_at >= ^today_start,
            where: is_nil(ac.id),
            order_by: [desc: ds.finished_at],
            limit: 1
          )
          |> Repo.one()

          if not is_nil(recent_ds) do
            {:ok, audit} = UserPoints.give_anticipation_points(recent_ds.admin_id)
            {:ok, candidate} = %AnticipationCandidate{
              user_id: recent_ds.admin_id,
              topic: topic,
              expire_at: DateTime.add(now, @cond_double_hour * 3600)
            }
            |> Repo.insert()

            Notifications.process_user_point_audit(audit, candidate)
          end
        end

      end)

    end
  end

end
