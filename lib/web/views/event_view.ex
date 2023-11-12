defmodule Web.EventView do
  use Web, :view
  alias BillBored.Event
  alias Web.Router.Helpers, as: Routes

  @fields [
    :id,
    :title,
    :categories,
    :date,
    :other_date,
    :price,
    :currency,
    :buy_ticket_link,
    :child_friendly,
    :inserted_at,
    :updated_at,
    :user_status,
    :invited_count,
    :refused_count,
    :accepted_count,
    :doubts_count,
    :missed_count,
    :presented_count
  ]

  def render("show.json", %{event: event}) do
    all_media = get_all_media(event)

    event
    |> Map.take(@fields)
    |> Map.put(:user_attending?, event.user_status == "accepted")
    #    |> Map.put(:location, Tuple.to_list(event.location.coordinates))
    |> Map.put(:location, render_one(event.location, Web.LocationView, "show.json"))
    # TODO rename to media_files
    |> Map.put(:media_file_keys, render_many(all_media, Web.MediaView, "show.json"))
    |> Map.put(:place, render_one(event.place, Web.PlaceView, "show.json"))
    |> Map.put(:attendees, render_many(event.attendees, Web.UserView, "min.json"))
    |> Map.put(:universal_link, Web.Helpers.universal_link(event.id, %{schema: Event}))
  end

  defp get_all_media(%Event{
         media_files: media_files,
         eventbrite_urls: eventbrite_urls,
         eventful_urls: eventful_urls,
         eventful_id: eventful_id,
         provider_urls: provider_urls,
         provider_id: provider_id,
         categories: categories
       }) do
    event_provider_media = cond do
      !is_nil(provider_id) -> provider_urls || []
      !is_nil(eventful_id) -> eventful_urls || []
      true -> eventbrite_urls || []
    end

    all_media = media_files ++ event_provider_media

    if eventful_id && Enum.empty?(all_media) do
      fallback_image_url =
        categories
        |> Enum.map(&fallback_image_url_for_category/1)
        |> Enum.reject(&is_nil/1)
        |> List.first()

      if fallback_image_url do
        [fallback_image_url]
      end
    end || all_media
  end

  defp fallback_image_url_for_category(category) do
    if image = fallback_image_for_category(category) do
      Web.Endpoint
      # TODO don't hardcode, get path from config
      |> Routes.static_url("/fallback_event_images")
      |> Path.join(image)
    end
  end

  @spec fallback_image_for_category(String.t()) :: image | nil when image: String.t()
  defp fallback_image_for_category(category)

  jpeg = [".jpg", ".jpeg"]

  Application.app_dir(:billbored, "priv/static/fallback_event_images")
  |> File.ls!()
  |> Enum.filter(&String.ends_with?(&1, jpeg))
  |> Enum.each(fn image ->
    category = String.replace(image, jpeg, "")
    defp fallback_image_for_category(unquote(category)), do: unquote(image)
  end)

  defp fallback_image_for_category(_category), do: nil
end
