defmodule Web.PostReportView do
  use Web, :view
  alias BillBored.PostReportReason

  def render("post_report_reason.json", %{
        post_report_reason: %PostReportReason{
          id: id,
          reason: report_reason
        }
      }) do
    %{
      "id" => id,
      "report_reason" => report_reason
    }
  end

  def render("post_report_reasons.json", %{post_report_reasons: post_report_reasons}) do
    Enum.map(post_report_reasons, fn %PostReportReason{} = post_report_reason ->
      render("post_report_reason.json", %{post_report_reason: post_report_reason})
    end)
  end
end
