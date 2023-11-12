defmodule Web.Torch.CovidInfoController do
  use Web, :controller

  alias BillBored.KVEntries.CovidInfo

  plug(:put_layout, {Web.LayoutView, "torch.html"})

  def show(conn, _params) do
    render(conn, "show.html", %{covid_info: covid_info!()})
  end

  def edit(conn, _params) do
    covid_info = covid_info!()
    changeset = CovidInfo.Value.changeset(covid_info.value)
    render(conn, "edit.html", value: covid_info.value, changeset: changeset)
  end

  def update(conn, %{"value" => value} = _params) do
    covid_info = covid_info!()

    case Repo.update(CovidInfo.changeset(covid_info, %{"value" => value})) do
      {:ok, _covid_info} ->
        conn
        |> put_flash(:info, "COVID info updated successfully.")
        |> redirect(to: Routes.torch_covid_info_path(conn, :show))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", covid_info: covid_info, changeset: changeset)
    end
  end

  defp covid_info!() do
    Repo.get!(CovidInfo, "covid_info")
  end
end