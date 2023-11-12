defmodule Web.PostReportController do
  use Web, :controller

  alias BillBored.PostReport

  action_fallback(Web.FallbackController)

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def create_post_report(
        %Plug.Conn{assigns: %{user_id: user_id}} = conn,
        %{"reporter_id" => user_id} = params,
        _opts
      ) do
    with {:ok, _post_report} <- BillBored.PostReports.create(params) do
      send_resp(conn, :ok, [])
    end
  end

  def create_post_report(_conn, _params, _opts) do
    changeset =
      Ecto.Changeset.change(%PostReport{})
      |> Ecto.Changeset.add_error(:reporter_id, "doesn't match current user")

    {:error, changeset}
  end

  def get_all_post_report_reason(conn, _params, _opts) do
    post_report_reasons = BillBored.PostReports.get_all_post_report_reasons()
    render(conn, "post_report_reasons.json", post_report_reasons: post_report_reasons)
  end
end
