defmodule BillBored.Torch.Notifications.AreaNotificationDecorator do
  @moduledoc false

  import Ecto.Changeset
  import Ecto.Query
  use Ecto.Schema

  alias BillBored.Torch.ImageUpload

  @required_fields [:owner_ref, :message, :latitude, :longitude, :radius]
  @max_radius_m 1_000_000.0

  @primary_key false
  embedded_schema do
    field :owner_ref, :string
    field :title, :string
    field :message, :string
    field :timezone, :string
    field :latitude, :float
    field :longitude, :float
    field :radius, :float

    belongs_to :owner, BillBored.User
    belongs_to :logo, ImageUpload, foreign_key: :logo_media_key, references: :media_key
    belongs_to :image, ImageUpload, foreign_key: :image_media_key, references: :media_key
  end

  def changeset(decorator, attrs \\ %{}) do
    decorator
    |> Map.merge(%{owner: nil, logo: nil, image: nil})
    |> cast(attrs, @required_fields ++ [:title, :timezone])
    |> validate_required(@required_fields)
    |> validate_timezone(:timezone)
    |> validate_number(:latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> validate_number(:radius, greater_than: 0, less_than_or_equal_to: @max_radius_m)
    |> cast_owner()
    |> cast_upload(:logo, attrs["logo"])
    |> cast_upload(:image, attrs["image"])
  end

  defp cast_owner(changeset) do
    case get_change(changeset, :owner_ref) do
      nil ->
        changeset

      value ->
        owner =
          case Integer.parse(value) do
            {id, ""} -> Repo.get(BillBored.User, id)
            _ -> from(u in BillBored.User, where: u.username == ^value) |> Repo.one()
          end

        if owner do
          put_assoc(changeset, :owner, owner)
        else
          add_error(changeset, :owner_ref, "invalid")
        end
    end
  end

  defp cast_upload(changeset, field, upload) do
    case upload do
      %Plug.Upload{} ->
        owner_id =
          case %{data: owner} = get_change(changeset, :owner) do
            nil -> nil
            _ -> owner.id
          end

        upload_changeset =
          ImageUpload.changeset(%ImageUpload{}, %{
            "owner_id" => owner_id,
            "media" => upload,
            "media_type" => "image"
          })

        case upload_changeset do
          %{valid?: true} ->
            put_assoc(changeset, field, upload_changeset)

          %{errors: errors} ->
            error =
              case Keyword.get(errors, :media) do
                nil -> :invalid
                error -> elem(error, 0)
              end

            add_error(changeset, field, error)
        end

      _ ->
        changeset
    end
  end

  defp validate_timezone(changeset, field) do
    case get_change(changeset, field) do
      nil ->
        changeset

      timezone ->
        if Timex.Timezone.exists?(timezone) do
          try do
            quoted_tz = Repo.quote_value(timezone)
            Ecto.Adapters.SQL.query!(Repo, "SELECT timezone(#{quoted_tz}, NOW())", [])
            changeset
          rescue
            _ ->
              add_error(changeset, field, "must be a valid timezone name")
          end
        else
          add_error(changeset, field, "must be a valid timezone name")
        end
    end
  end
end
