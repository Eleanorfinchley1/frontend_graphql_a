defmodule BillBored.Notifications.AreaNotifications do
  @moduledoc false

  import Ecto.Query
  import Geo.PostGIS, only: [st_dwithin_in_meters: 3]

  alias BillBored.Notifications.AreaNotification
  alias BillBored.Notifications.AreaNotificationReception

  @default_page_size 30

  def get_for_business(business_id, id) do
    case from(a in AreaNotification, where: a.id == ^id and a.business_id == ^business_id)
         |> Repo.one() do
      %AreaNotification{} = area_notification -> {:ok, area_notification}
      _ -> {:error, :not_found}
    end
  end

  defp validate_categories(nil), do: :ok
  defp validate_categories([]), do: :ok

  defp validate_categories(list) when is_list(list),
    do: BillBored.InterestCategories.validate(list)

  defp validate_categories(_), do: {:error, :invalid_categories}

  defp validate_linked_post(_business_id, nil), do: :ok

  defp validate_linked_post(business_id, linked_post_id) do
    case BillBored.Posts.get_for_business(business_id, linked_post_id) do
      {:ok, _post} -> :ok
      {:error, :not_found} -> {:error, :invalid_linked_post_id}
      error -> error
    end
  end

  def create(attrs) do
    with :ok <- validate_categories(attrs[:categories]),
         :ok <- validate_linked_post(attrs[:business_id], attrs[:linked_post_id]),
         {:ok, area_notification} <-
           AreaNotification.changeset(%AreaNotification{}, attrs) |> Repo.insert() do
      {:ok, area_notification |> Repo.preload([:owner, :business, :logo, :image])}
    end
  end

  def delete(%AreaNotification{} = area_notification) do
    Repo.delete(area_notification)
  end

  def list_for_business(business_id, params) do
    page = params[:page] || 1
    page_size = params[:page_size] || @default_page_size
    offset = page_size * (page - 1)

    query =
      from(a in AreaNotification,
        where: a.business_id == ^business_id,
        order_by: [desc: :inserted_at, desc: :id],
        limit: ^page_size,
        offset: ^offset,
        join: b in assoc(a, :business),
        join: o in assoc(a, :owner),
        left_join: l in assoc(a, :logo),
        left_join: i in assoc(a, :image),
        preload: [business: b, owner: o, logo: l, image: i]
      )

    %{
      page: page,
      page_size: page_size,
      entries: Repo.all(query)
    }
  end

  def add_receivers(%AreaNotification{id: area_notification_id}, user_ids) do
    now = Timex.now()

    items =
      user_ids
      |> Enum.map(fn user_id ->
        %{area_notification_id: area_notification_id, user_id: user_id, inserted_at: now}
      end)

    Repo.insert_all(AreaNotificationReception, items,
      conflict_target: [:user_id, :area_notification_id],
      on_conflict: :nothing
    )
  end

  def update_receivers_count(%{id: id} = _notification) do
    count_query =
      from(nr in AreaNotificationReception,
        select: %{count: count(nr)},
        where: nr.area_notification_id == ^id,
        group_by: nr.area_notification_id
      )

    from(n in AreaNotification,
      join: cnt in subquery(count_query),
      on: true,
      where: n.id == ^id,
      update: [set: [receivers_count: cnt.count]]
    )
    |> Repo.update_all([])
  end

  def find_matching(user_id, %BillBored.Geo.Point{} = location) do
    from(n in AreaNotification,
      select: n,
      distinct: n.id,
      order_by: [desc: n.inserted_at],
      join: u in BillBored.User,
      on: u.id == ^user_id,
      left_join: nr in AreaNotificationReception,
      on: nr.user_id == u.id and nr.area_notification_id == n.id,
      left_join: ui in assoc(u, :interests_interest),
      left_join: ic in assoc(ui, :interest_categories),
      on: ic.name in n.categories,
      where:
        is_nil(nr.id) and
          (is_nil(n.expires_at) or n.expires_at > fragment("NOW()")) and
          st_dwithin_in_meters(n.location, ^location, n.radius) and
          (is_nil(n.sex) or fragment("UPPER(?) = UPPER(?)", n.sex, u.sex)) and
          (is_nil(n.max_age) or
             (not is_nil(u.birthdate) and
                fragment("(? + interval '1' year * ?) > NOW()", u.birthdate, n.max_age))) and
          (is_nil(n.min_age) or
             (not is_nil(u.birthdate) and
                fragment("(? + interval '1' year * ?) < NOW()", u.birthdate, n.min_age))) and
          (is_nil(n.categories) or not is_nil(ic.name)),
      limit: 1
    )
    |> Repo.one()
    |> Repo.preload([:owner, :business, :logo, :image])
  end

  def get_scheduled(user_id) do
    now = DateTime.utc_now()
    yesterday = Timex.shift(Timex.beginning_of_day(now), days: -1)

    notifications_query =
      from(n in BillBored.Notification,
        order_by: [desc: n.timestamp],
        select: n.id,
        limit: 1,
        where:
          n.recipient_id == ^user_id and
          n.verb == "area_notifications:scheduled" and
          n.timestamp >= ^yesterday
      )

    from(n in AreaNotification,
      join: nan in BillBored.Notifications.NotificationAreaNotification,
      on: nan.area_notification_id == n.id,
      where:
        nan.notification_id in subquery(notifications_query) and
        (is_nil(n.expires_at) or n.expires_at >= ^now)
    )
    |> Repo.all()
    |> Repo.preload([:owner, :business, :logo, :image])
  end
end
