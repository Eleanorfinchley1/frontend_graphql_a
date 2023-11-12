defmodule BillBored.Feedback do
  @moduledoc "schema for appnotifications_device table"

  use BillBored, :schema

  @type t :: %__MODULE__{}

  schema "accounts_feedback" do
    field(:feedback_type, :string)
    field(:message, :string)
    field(:feedback_image, :string)

    timestamps(inserted_at: :created, updated_at: :updated)
  end

  @doc false
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [
      :message,
      :feedback_type,
      :feedback_image
    ])
  end
end
