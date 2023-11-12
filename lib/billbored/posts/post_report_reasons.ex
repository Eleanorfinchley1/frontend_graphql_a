defmodule BillBored.PostReportReasons do
  @moduledoc ""

  alias BillBored.{PostReportReason}

  def find_all_post_report_reasons do
    PostReportReason
    |> Repo.all()
  end
end
