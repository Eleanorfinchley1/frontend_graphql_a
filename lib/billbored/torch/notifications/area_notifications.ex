defmodule BillBored.Torch.Notifications.AreaNotifications do
  @moduledoc false

  import Ecto.Query
  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias BillBored.Torch.Notifications.AreaNotificationDecorator
  alias BillBored.Notifications.AreaNotification

  @pagination [page_size: 15]
  @pagination_distance 5

  def create(%AreaNotificationDecorator{} = decorator) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:insert_logo, fn _, _ ->
        if decorator.logo do
          with {:ok, logo} <- Repo.insert(decorator.logo) do
            {:ok, logo.media_key}
          end
        else
          {:ok, nil}
        end
      end)
      |> Ecto.Multi.run(:insert_image, fn _, _ ->
        if decorator.image do
          with {:ok, image} <- Repo.insert(decorator.image) do
            {:ok, image.media_key}
          end
        else
          {:ok, nil}
        end
      end)
      |> Ecto.Multi.run(:insert_notification, fn _,
                                                 %{
                                                   insert_logo: logo_media_key,
                                                   insert_image: image_media_key
                                                 } ->
        AreaNotification.changeset(%AreaNotification{}, %{
          "owner_id" => decorator.owner.id,
          "title" => decorator.title,
          "message" => decorator.message,
          "timezone" => decorator.timezone,
          "location" => %BillBored.Geo.Point{long: decorator.longitude, lat: decorator.latitude},
          "radius" => decorator.radius,
          "logo_media_key" => logo_media_key,
          "image_media_key" => image_media_key
        })
        |> Repo.insert()
      end)
      |> Repo.transaction()

    with {:ok, %{insert_notification: notification}} <- result do
      {:ok, Repo.preload(notification, [:owner, :logo, :image])}
    end
  end

  def get!(id) do
    Repo.get!(AreaNotification, id)
    |> Repo.preload([:owner, :logo, :image])
  end

  def delete(%AreaNotification{logo: logo, image: image} = notification) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:delete_notification, fn _, _ ->
        Repo.delete(notification)
      end)
      |> Ecto.Multi.run(:delete_logo, fn _, _ ->
        if notification.logo_media_key do
          Repo.delete(logo)
        else
          {:ok, nil}
        end
      end)
      |> Ecto.Multi.run(:delete_image, fn _, _ ->
        if notification.image_media_key do
          Repo.delete(image)
        else
          {:ok, nil}
        end
      end)
      |> Repo.transaction()

    with {:ok, results} <- result do
      if logo = Map.get(results, :delete_logo) do
        :ok = BillBored.Torch.Uploads.ImageFile.delete({logo.media, logo})
      end

      if image = Map.get(results, :delete_image) do
        :ok = BillBored.Torch.Uploads.ImageFile.delete({image.media, image})
      end

      {:ok, Map.get(results, :delete_notification)}
    end
  end

  def paginate_area_notifications(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <-
           Filtrex.parse_params(
             filter_config(:area_notifications),
             params["area_notification"] || %{}
           ),
         %Scrivener.Page{} = page <- do_paginate_area_notifications(filter, params) do
      {:ok,
       %{
         area_notifications: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate_area_notifications(filter, params) do
    AreaNotification
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  defp filter_config(:area_notifications) do
    defconfig do
      number(:id)
      number(:owner_id)
      number(:radius)
      number(:receivers_count)
      datetime(:inserted_at)
      datetime(:expres_at)
    end
  end
end
