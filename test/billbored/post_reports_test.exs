defmodule BillBored.PostReportsTest do
  use BillBored.DataCase, async: true
  alias BillBored.{Post, PostReports}

  describe "#count_reports" do
    setup do
      post = insert(:post)
      insert(:post_report, post: post)

      another_post = insert(:post)
      insert(:post_report, post: another_post)
      insert(:post_report, post: another_post)

      %{post: post, another_post: another_post}
    end

    test "returns count of post reports", %{post: post, another_post: another_post} do
      assert 1 == PostReports.count_reports(post)
      assert 2 == PostReports.count_reports(another_post.id)
    end
  end

  describe "#create" do
    def create_post_report(post, user, reason) do
      PostReports.create(%{
        "post_id" => post.id,
        "reporter_id" => user.id,
        "reason_id" => reason.id
      })
    end

    setup do
      user = insert(:user)
      post = insert(:post)
      reason = insert(:post_report_reason)
      %{user: user, post: post, reason: reason}
    end

    test "creates a new report for post", %{user: user, post: post, reason: reason} do
      assert {:ok, _report} = create_post_report(post, user, reason)
      assert 1 == PostReports.count_reports(post.id)
    end

    test "user can't report one post twice with the same reason", %{
      post: post,
      user: user,
      reason: reason
    } do
      create_post_report(post, user, reason)

      assert {:error, :insert_report, %{errors: [report: {"has already been filed", _}]}, _} =
               create_post_report(post, user, reason)
    end

    test "hides and marks post for review when it's reported more than 5 times", %{
      user: user,
      post: post,
      reason: reason
    } do
      insert_list(4, :post_report, post: post, reason: reason)
      assert {:ok, _report} = create_post_report(post, user, reason)

      assert %{hidden?: true, review_status: "pending"} = Repo.get!(Post, post.id)
    end

    test "if post has been reviewed only count new reports", %{
      user: user,
      reason: reason
    } do
      post = insert(:post, review_status: nil, last_reviewed_at: ~U[2020-01-15 12:15:00.000000Z])
      insert_list(3, :post_report, post: post, reason: reason, inserted_at: ~U[2020-01-15 12:00:00Z])
      insert_list(3, :post_report, post: post, reason: reason, inserted_at: ~U[2020-01-15 12:16:00Z])

      assert {:ok, _report} = create_post_report(post, user, reason)
      assert %{hidden?: false, review_status: nil} = Repo.get!(Post, post.id)

      assert {:ok, _report} = create_post_report(post, insert(:user), reason)
      assert %{hidden?: true, review_status: "pending"} = Repo.get!(Post, post.id)
    end

    test "does not change review_status from 'rejected' when post is hidden", %{
      user: user,
      reason: reason
    } do
      post = insert(:post, review_status: "rejected")
      insert_list(4, :post_report, post: post, reason: reason)
      assert {:ok, _report} = create_post_report(post, user, reason)

      assert %{hidden?: true, review_status: "rejected"} = Repo.get!(Post, post.id)
    end

    test "does not hide or change review_status when post is accepted", %{
      user: user,
      reason: reason
    } do
      post = insert(:post, review_status: "accepted")
      insert_list(4, :post_report, post: post, reason: reason)
      assert {:ok, _report} = create_post_report(post, user, reason)

      assert %{hidden?: false, review_status: "accepted"} = Repo.get!(Post, post.id)
    end
  end

  describe "#get_all_post_report_reasons" do
    setup do
      reason1 = insert(:post_report_reason, reason: "inappropriate")
      reason2 = insert(:post_report_reason, reason: "spam")
      reason3 = insert(:post_report_reason, reason: "bad")

      %{reasons: [reason3, reason1, reason2]}
    end

    test "returns all post report reasons", %{reasons: reasons} do
      assert PostReports.get_all_post_report_reasons() |> Enum.map(& &1.reason) |> Enum.sort() ==
               reasons |> Enum.map(& &1.reason) |> Enum.sort()
    end
  end
end
