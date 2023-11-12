defmodule Web.PostReportControllerTest do
  use Web.ConnCase, async: true
  import Ecto.Query
  alias BillBored.PostReport

  setup %{conn: conn} do
    %{user: user, key: token} = insert(:auth_token)
    {:ok, conn: put_req_header(conn, "authorization", "Bearer #{token}"), user: user}
  end

  describe "#get_all_post_report_reason" do
    setup do
      reason1 = insert(:post_report_reason, reason: "inappropriate")
      reason2 = insert(:post_report_reason, reason: "spam")

      %{reasons: [reason1, reason2]}
    end

    test "returns a list of all report reasons for posts", %{
      conn: conn,
      reasons: [reason1, reason2]
    } do
      response =
        conn
        |> get(Routes.post_report_path(conn, :get_all_post_report_reason))
        |> json_response(200)
        |> Enum.sort_by(& &1["id"])

      assert response |> Enum.at(0) == %{"id" => reason1.id, "report_reason" => reason1.reason}
      assert response |> Enum.at(1) == %{"id" => reason2.id, "report_reason" => reason2.reason}
    end
  end

  describe "#create_post_report" do
    setup do
      post = insert(:post)
      reason = insert(:post_report_reason)

      %{post: post, reason: reason}
    end

    test "create a new report", %{conn: conn, post: post, user: user, reason: reason} do
      payload = %{
        "post_id" => post.id,
        "reporter_id" => user.id,
        "reason_id" => reason.id
      }

      assert "" =
               conn
               |> post(Routes.post_report_path(conn, :create_post_report), payload)
               |> response(200)

      report =
        from(pr in PostReport,
          where: pr.post_id == ^post.id,
          order_by: [desc: pr.inserted_at],
          limit: 1
        )
        |> Repo.one!()

      assert report.post_id == post.id
      assert report.reporter_id == user.id
      assert report.reason_id == reason.id
    end

    test "returns error if trying to create duplicate report", %{
      conn: conn,
      post: post,
      user: user,
      reason: reason
    } do
      insert(:post_report, post: post, user: user, reason: reason)

      payload = %{
        "post_id" => post.id,
        "reporter_id" => user.id,
        "reason_id" => reason.id
      }

      assert %{"reason" => %{"report" => ["has already been filed"]}, "success" => false} =
               conn
               |> post(Routes.post_report_path(conn, :create_post_report), payload)
               |> json_response(422)
    end

    test "returns 422 if post_id is invalid", %{conn: conn, user: user, reason: reason} do
      payload = %{
        "post_id" => 0,
        "reporter_id" => user.id,
        "reason_id" => reason.id
      }

      assert %{"reason" => %{"post_id" => ["does not exist"]}, "success" => false} =
               conn
               |> post(Routes.post_report_path(conn, :create_post_report), payload)
               |> json_response(422)
    end

    test "returns 422 if reason_id is invalid", %{conn: conn, post: post, user: user} do
      payload = %{
        "post_id" => post.id,
        "reporter_id" => user.id,
        "reason_id" => 0
      }

      assert %{"reason" => %{"reason_id" => ["does not exist"]}, "success" => false} =
               conn
               |> post(Routes.post_report_path(conn, :create_post_report), payload)
               |> json_response(422)
    end

    test "returns 422 if reporter_id is invalid", %{conn: conn, post: post, reason: reason} do
      payload = %{
        "post_id" => post.id,
        "reporter_id" => 0,
        "reason_id" => reason.id
      }

      assert %{
               "reason" => %{"reporter_id" => ["doesn't match current user"]},
               "success" => false
             } =
               conn
               |> post(Routes.post_report_path(conn, :create_post_report), payload)
               |> json_response(422)
    end

    test "returns 422 if reporter_id does not match current user", %{
      conn: conn,
      post: post,
      reason: reason
    } do
      another_user = insert(:user)

      payload = %{
        "post_id" => post.id,
        "reporter_id" => another_user.id,
        "reason_id" => reason.id
      }

      assert %{
               "reason" => %{"reporter_id" => ["doesn't match current user"]},
               "success" => false
             } =
               conn
               |> post(Routes.post_report_path(conn, :create_post_report), payload)
               |> json_response(422)
    end
  end
end
