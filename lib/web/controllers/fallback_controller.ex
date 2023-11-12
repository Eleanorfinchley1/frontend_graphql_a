defmodule Web.FallbackController do
  use Web, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    # https://httpstatuses.com/422

    conn
    |> put_status(:unprocessable_entity)
    |> put_view(Web.ErrorView)
    |> render("changeset.json", changeset: changeset)
  end

  def call(conn, {:error, multi_step, %Ecto.Changeset{} = changeset, changes}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(Web.ErrorView)
    |> render("multi_changeset.json", multi_step: multi_step, changes: changes, changeset: changeset)
  end

  def call(conn, {:error, _multi_step, reason, _changes}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(Web.ErrorView)
    |> render("unprocessable.json", %{reason: to_string(reason)})
  end

  def call(conn, {:error, :not_found} = error) do
    conn
    |> put_status(:not_found)
    |> put_view(Web.ErrorView)
    |> render("404.json", %{error: error})
  end

  def call(conn, {:error, reason}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(Web.ErrorView)
    |> render("unprocessable.json", %{reason: reason})
  end

  def call(conn, {:error, reason, details}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(Web.ErrorView)
    |> render("unprocessable.json", %{reason: reason, details: details})
  end
end
