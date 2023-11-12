defmodule BillBored.PostReports do
  @moduledoc ""

  import Ecto.Query
  alias BillBored.{Post, PostReport}

  @reports_to_hide_post 5

  def create(attrs) do
    with {:ok, %{insert_block: result}} <-
      Ecto.Multi.new()
      |> Ecto.Multi.run(:insert_report, fn _repo, _ ->
        %PostReport{}
        |> PostReport.changeset(attrs)
        |> Repo.insert()
      end)
      |> Ecto.Multi.run(:maybe_hide_post, fn _repo, %{insert_report: report} ->
        maybe_hide_post(report.post_id)
      end)
      |> Repo.transaction() do
      {:ok, result}
    end
  end

  defp maybe_hide_post(post_id) do
    posts_with_reports_count = from(p in Post,
      left_join: r in assoc(p, :reports),
      on: is_nil(p.last_reviewed_at) or (r.inserted_at >= p.last_reviewed_at),
      select: %{
        id: p.id,
        count: fragment("count(?)", r.id),
        review_status: fragment("CASE WHEN (? IS NULL) THEN ? ELSE ? END", p.review_status, "pending", p.review_status)
      },
      where: p.id == ^post_id and fragment("? IS DISTINCT FROM ?", p.review_status, "accepted"),
      group_by: p.id,
      having: fragment("count(?)", r.id) >= ^@reports_to_hide_post
    )

    result =
      from(p in Post,
        inner_join: pp in subquery(posts_with_reports_count),
        on: p.id == pp.id,
        update: [set: [hidden?: true, review_status: pp.review_status]]
      )
      |> Repo.update_all([])

    {:ok, result}
  end

  def find_all_reports do
    PostReport
    |> preload([:user, :post])
    |> Repo.all()
  end

  def count_reports(%Post{id: post_id} = _post), do: count_reports(post_id)

  def count_reports(post_id) do
    query = from(pr in PostReport, where: pr.post_id == ^post_id)
    Repo.aggregate(query, :count, :post_id)
  end

  def get_all_post_report_reasons do
    BillBored.PostReportReasons.find_all_post_report_reasons()
  end
end
