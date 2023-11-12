defmodule Web.CovidController do
  use Web, :controller
  alias BillBored.Covid.Cases, as: CovidCases

  action_fallback Web.FallbackController

  def list_by_country(conn, _params) do
    with date <- CovidCases.get_latest_date(),
         cases <- CovidCases.list_per_country(date),
         worldwide <- CovidCases.get_worldwide_summary(date),
         info <- CovidCases.get_info() do
      render(conn, "index.json", %{data: cases, worldwide: worldwide, info: info, updated_at: date})
    end
  end

  def list_by_region(conn, _params) do
    with date <- CovidCases.get_latest_date(),
         cases <- CovidCases.list_per_region(date) do
      render(conn, "index.json", %{data: cases, updated_at: date})
    end
  end
end
