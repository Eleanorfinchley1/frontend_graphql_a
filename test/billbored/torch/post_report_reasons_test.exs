defmodule BillBored.Torch.PostReportReasonsTest do
  use BillBored.DataCase, async: true

  alias BillBored.PostReportReason
  alias BillBored.Torch.PostReportReasons

  describe "post_report_reasons" do
    @valid_attrs %{reason: "some reason"}
    @update_attrs %{reason: "some updated reason"}
    @invalid_attrs %{reason: nil}

    def post_report_reason_fixture(attrs \\ %{}) do
      {:ok, post_report_reason} =
        attrs
        |> Enum.into(@valid_attrs)
        |> PostReportReasons.create_post_report_reason()

      post_report_reason
    end

    test "paginate_post_report_reasons/1 returns paginated list of post_report_reasons" do
      for _ <- 1..20 do
        insert(:post_report_reason)
      end

      {:ok, %{post_report_reasons: post_report_reasons} = page} =
        PostReportReasons.paginate_post_report_reasons(%{})

      assert length(post_report_reasons) == 15
      assert page.page_number == 1
      assert page.page_size == 15
      assert page.total_pages == 2
      assert page.total_entries == 20
      assert page.distance == 5
      assert page.sort_field == "inserted_at"
      assert page.sort_direction == "desc"
    end

    test "list_post_report_reasons/0 returns all post_report_reasons" do
      post_report_reason = post_report_reason_fixture()

      assert PostReportReasons.list_post_report_reasons() |> Enum.map(& &1.id) == [
               post_report_reason.id
             ]
    end

    test "get_post_report_reason!/1 returns the post_report_reason with given id" do
      post_report_reason = post_report_reason_fixture()

      assert PostReportReasons.get_post_report_reason!(post_report_reason.id).id ==
               post_report_reason.id
    end

    test "create_post_report_reason/1 with valid data creates a post_report_reason" do
      assert {:ok, %PostReportReason{} = post_report_reason} =
               PostReportReasons.create_post_report_reason(@valid_attrs)

      assert post_report_reason.reason == "some reason"
    end

    test "create_post_report_reason/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               PostReportReasons.create_post_report_reason(@invalid_attrs)
    end

    test "update_post_report_reason/2 with valid data updates the post_report_reason" do
      post_report_reason = post_report_reason_fixture()

      assert {:ok, post_report_reason} =
               PostReportReasons.update_post_report_reason(post_report_reason, @update_attrs)

      assert %PostReportReason{} = post_report_reason
      assert post_report_reason.reason == "some updated reason"
    end

    test "update_post_report_reason/2 with invalid data returns error changeset" do
      post_report_reason = post_report_reason_fixture()

      assert {:error, %Ecto.Changeset{}} =
               PostReportReasons.update_post_report_reason(post_report_reason, @invalid_attrs)

      assert post_report_reason.id ==
               PostReportReasons.get_post_report_reason!(post_report_reason.id).id
    end

    test "delete_post_report_reason/1 deletes the post_report_reason" do
      post_report_reason = post_report_reason_fixture()

      assert {:ok, %PostReportReason{}} =
               PostReportReasons.delete_post_report_reason(post_report_reason)

      assert_raise Ecto.NoResultsError, fn ->
        PostReportReasons.get_post_report_reason!(post_report_reason.id)
      end
    end

    test "change_post_report_reason/1 returns a post_report_reason changeset" do
      post_report_reason = post_report_reason_fixture()
      assert %Ecto.Changeset{} = PostReportReasons.change_post_report_reason(post_report_reason)
    end
  end
end
