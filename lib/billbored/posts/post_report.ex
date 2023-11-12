defmodule BillBored.PostReport do
  @moduledoc "schema for post report table"

  use BillBored, :schema
  alias BillBored.{User, Post, PostReportReason}

  @type t :: %__MODULE__{}

  schema "post_reports" do
    belongs_to(:post, Post)
    belongs_to(:user, User, foreign_key: :reporter_id)
    belongs_to(:reason, PostReportReason, foreign_key: :reason_id)

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:post_id, :reporter_id, :reason_id])
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:reporter_id)
    |> foreign_key_constraint(:reason_id)
    |> unique_constraint(:report,
      name: :post_reports_post_id_reporter_id_reason_id_index,
      message: "has already been filed"
    )
  end
end
