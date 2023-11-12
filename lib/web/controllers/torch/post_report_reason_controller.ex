defmodule Web.Torch.PostReportReasonController do
  use Web, :controller

  alias BillBored.PostReportReason
  alias BillBored.Torch.PostReportReasons

  plug(:put_layout, {Web.LayoutView, "torch.html"})

  def index(conn, params) do
    case PostReportReasons.paginate_post_report_reasons(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)
      error ->
        conn
        |> put_flash(:error, "There was an error rendering Post report reasons. #{inspect(error)}")
        |> redirect(to: Routes.torch_post_report_reason_path(conn, :index))
    end
  end

  def new(conn, _params) do
    changeset = PostReportReasons.change_post_report_reason(%PostReportReason{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"post_report_reason" => post_report_reason_params}) do
    case PostReportReasons.create_post_report_reason(post_report_reason_params) do
      {:ok, post_report_reason} ->
        conn
        |> put_flash(:info, "Post report reason created successfully.")
        |> redirect(to: Routes.torch_post_report_reason_path(conn, :show, post_report_reason))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    post_report_reason = PostReportReasons.get_post_report_reason!(id)
    render(conn, "show.html", post_report_reason: post_report_reason)
  end

  def edit(conn, %{"id" => id}) do
    post_report_reason = PostReportReasons.get_post_report_reason!(id)
    changeset = PostReportReasons.change_post_report_reason(post_report_reason)
    render(conn, "edit.html", post_report_reason: post_report_reason, changeset: changeset)
  end

  def update(conn, %{"id" => id, "post_report_reason" => post_report_reason_params}) do
    post_report_reason = PostReportReasons.get_post_report_reason!(id)

    case PostReportReasons.update_post_report_reason(post_report_reason, post_report_reason_params) do
      {:ok, post_report_reason} ->
        conn
        |> put_flash(:info, "Post report reason updated successfully.")
        |> redirect(to: Routes.torch_post_report_reason_path(conn, :show, post_report_reason))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", post_report_reason: post_report_reason, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    post_report_reason = PostReportReasons.get_post_report_reason!(id)
    {:ok, _post_report_reason} = PostReportReasons.delete_post_report_reason(post_report_reason)

    conn
    |> put_flash(:info, "Post report reason deleted successfully.")
    |> redirect(to: Routes.torch_post_report_reason_path(conn, :index))
  end
end