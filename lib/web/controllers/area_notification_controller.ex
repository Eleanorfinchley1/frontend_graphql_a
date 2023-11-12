defmodule Web.AreaNotificationController do
  use Web, :controller

  import BillBored.ServiceRegistry, only: [service: 1]

  alias BillBored.Users
  alias BillBored.Notifications.AreaNotifications

  require Logger

  action_fallback(Web.FallbackController)

  @create_business_area_notification_params [
    {"title", :title, true},
    {"message", :message, true},
    {"location", :location, true},
    {"radius", :radius, true},
    {"expires_at", :expires_at, true},
    {"logo", :logo_media_key, true},
    {"image", :image_media_key, true},
    {"categories", :categories, false},
    {"sex", :sex, false},
    {"min_age", :min_age, false},
    {"max_age", :max_age, false},
    {"linked_post_id", :linked_post_id, false}
  ]

  def create_business_area_notification(%{assigns: %{user_id: user_id}} = conn, params) do
    with {:ok, valid_params} <-
           validate_params(@create_business_area_notification_params, params),
         {:ok, business} <- Users.get_business_account(id: params["business_id"]) do
      attrs = Map.merge(valid_params, %{owner_id: user_id, business_id: business.id})

      case AreaNotifications.Policy.authorize(:create_business_area_notification, attrs, user_id) do
        true ->
          with {:ok, area_notification} <- AreaNotifications.create(attrs) do
            match_data = AreaNotifications.MatchData.new(area_notification)
            service(Web.AreaNotificationChannel).notify(area_notification, match_data)
            render(conn, "show.json", area_notification: area_notification)
          end

        {false, reason} ->
          Logger.debug("Can't create area notification: #{inspect(reason)}")
          send_resp(conn, 403, [])
      end
    end
  end

  def delete_business_area_notification(%{assigns: %{user_id: user_id}} = conn, %{
        "business_id" => business_id,
        "id" => area_notification_id
      }) do
    with {:ok, area_notification} <-
           AreaNotifications.get_for_business(business_id, area_notification_id) do
      case AreaNotifications.Policy.authorize(
             :delete_business_area_notification,
             area_notification,
             user_id
           ) do
        true ->
          with {:ok, _} <- AreaNotifications.delete(area_notification) do
            send_resp(conn, 204, [])
          end

        {false, reason} ->
          Logger.debug("Can't delete area notification: #{inspect(reason)}")
          send_resp(conn, 403, [])
      end
    end
  end

  @list_business_area_notifications_params [
    {"business_id", :business_id, true},
    {"page", :page, false},
    {"page_size", :page_size, false}
  ]

  def list_business_area_notifications(%{assigns: %{user_id: user_id}} = conn, params) do
    with {:ok, valid_params} <- validate_params(@list_business_area_notifications_params, params) do
      case AreaNotifications.Policy.authorize(
             :list_business_area_notifications,
             valid_params,
             user_id
           ) do
        true ->
          %{
            page: page,
            page_size: page_size,
            entries: area_notifications
          } = AreaNotifications.list_for_business(valid_params[:business_id], valid_params)

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            200,
            Jason.encode!(%{
              page: page,
              page_size: page_size,
              entries:
                Phoenix.View.render_many(
                  area_notifications,
                  Web.AreaNotificationView,
                  "show.json"
                )
            })
          )

        {false, reason} ->
          Logger.debug("Can't list area notifications: #{inspect(reason)}")
          send_resp(conn, 403, [])
      end
    end
  end
end
