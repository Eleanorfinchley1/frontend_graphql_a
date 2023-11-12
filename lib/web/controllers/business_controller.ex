defmodule Web.BusinessController do
  use Web, :controller
  alias BillBored.{BusinessCategory, BusinessCategories}

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def create_business_category(conn, params, _opts) do
    with {:ok, %BusinessCategory{}} <- BusinessCategories.create(params) do
      send_resp(conn, 201, Jason.encode!(%{message: "Category created!"}, pretty: true))
    end
  end

  def get_paginate_categories(
        conn,
        %{"last_seen_param" => last_seen_param, "direction_param" => direction_param},
        _opts
      ) do
    categories = BillBored.Businesses.get_all_categories(last_seen_param, direction_param)
    render(conn, "categories.json", categories: categories)
  end

  def add_business_categories(conn, %{"categories_to_add" => categories_to_add}, current_user_id) do
    BillBored.Businesses.add_categories_to_business(categories_to_add, current_user_id)
    send_resp(conn, 201, Jason.encode!(%{message: "Categories added!"}, pretty: true))
  end
end
