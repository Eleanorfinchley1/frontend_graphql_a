defmodule BillBored.Upload do
  @moduledoc "schema for upload_fileupload table"

  use BillBored, :schema
  alias BillBored.User
  alias BillBored.Uploads.File
  use Arc.Ecto.Schema

  @type t :: %__MODULE__{}

  @primary_key false
  schema "upload_fileupload" do
    belongs_to(:owner, User)

    field(:media_key, :string, primary_key: true)
    field(:media, File.Type)
    field(:media_type, :string, default: "other")
    field(:media_thumbnail, :string, virtual: true)

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [
      :owner_id,
      :media_type,
      :media_key,
      :media_thumbnail
    ])
    |> check_uuid()
    |> validate_inclusion(:media_type, ["image", "video", "audio", "other"])
    |> cast_attachments(attrs, [:media])
    |> validate_required([:media, :owner_id, :media_key])
  end

  defp check_uuid(changeset) do
    case get_field(changeset, :media_key) do
      nil ->
        force_change(changeset, :media_key, UUID.uuid4())

      _ ->
        changeset
    end
  end
end
