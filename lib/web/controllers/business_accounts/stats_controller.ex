defmodule Web.BusinessAccounts.StatsController do
  use Web, :controller
  require Logger
  import BillBored.ServiceRegistry, only: [service: 1]
  alias BillBored.BusinessAccounts.Stats.Policy

  action_fallback(Web.FallbackController)

  @accuracy_radius 1_000

  def post_views(%{assigns: %{user_id: user_id}} = conn, %{"post_id" => post_id} = params) do
    case Policy.authorize(:post_views, params, user_id) do
      true ->
        with {:ok, result} <- service(BillBored.Clickhouse.PostViews).get_post_views(post_id, @accuracy_radius) do
          json(conn, Web.BusinessAccounts.StatsView.render("post_views.json", result))
        end

      {false, reason} ->
        Logger.debug("Access denied to post views stats: #{inspect(reason)}")
        send_resp(conn, 403, [])
    end
  end

  def post_stats(%{assigns: %{user_id: user_id}} = conn, %{"post_id" => post_id} = params) do
    case Policy.authorize(:post_stats, params, user_id) do
      true ->
        with {:ok, stats} <- service(BillBored.Clickhouse.PostViews).get_post_stats(post_id) do
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(stats))
        end

      {false, reason} ->
        Logger.debug("Access denied to post stats: #{inspect(reason)}")
        send_resp(conn, 403, [])
    end
  end

  def stats(%{assigns: %{user_id: user_id}} = conn, %{"business_id" => business_id} = params) do
    case Policy.authorize(:stats, params, user_id) do
      true ->
        with {:ok, stats} <- service(BillBored.Clickhouse.PostViews).get_business_stats(business_id) do
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(stats))
        end

      {false, reason} ->
        Logger.debug("Access denied to business stats: #{inspect(reason)}")
        send_resp(conn, 403, [])
    end
  end
end
