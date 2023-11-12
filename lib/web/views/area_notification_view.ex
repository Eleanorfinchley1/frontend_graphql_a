defmodule Web.AreaNotificationView do
  use Web, :view

  alias Web.ViewHelpers

  def render("show.json", %{area_notification: %{location: location} = notification}) do
    logo_url =
      if notification.logo && Ecto.assoc_loaded?(notification.logo) do
        BillBored.Uploads.File.url({notification.logo.media, notification.logo}, :original,
          signed: true
        ) || ""
      else
        ""
      end

    image_url =
      if notification.image && Ecto.assoc_loaded?(notification.image) do
        BillBored.Uploads.File.url({notification.image.media, notification.image}, :original,
          signed: true
        ) || ""
      else
        ""
      end

    Map.take(notification, [
      :id,
      :message,
      :radius,
      :expires_at,
      :inserted_at,
      :categories,
      :sex,
      :min_age,
      :max_age,
      :linked_post_id
    ])
    |> Map.put(:title, notification.title || "")
    |> Map.put(:location, Phoenix.View.render_one(location, Web.LocationView, "show.json"))
    |> ViewHelpers.put_assoc(:owner, notification.owner, Web.UserView, "min.json")
    |> ViewHelpers.put_assoc(:business, notification.business, Web.UserView, "min.json")
    |> Map.put(:logo_url, logo_url)
    |> Map.put(:image_url, image_url)
  end
end
