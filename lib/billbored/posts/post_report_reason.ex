defmodule BillBored.PostReportReason do
  @moduledoc "schema for post report reasons table"

  use BillBored, :schema

  schema "post_report_reasons" do
    field :reason, :string

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  @doc false
  def changeset(post_report_reason, attrs) do
    post_report_reason
    |> cast(attrs, [:reason])
    |> validate_length(:reason, max: 255)
    |> validate_required([:reason])
  end
end
