defmodule BillBored.Interest do
  import Ecto.Changeset
  use BillBored, :schema

  @type t :: %__MODULE__{}

  schema "interests" do
    field(:hashtag, :string)
    field(:icon, :string)
    field(:disabled?, :boolean, default: false)

    field(:popularity, :integer, virtual: true)
    field(:posts_count, :integer, virtual: true)
    field(:comments_count, :integer, virtual: true)
    field(:category_rn, :integer, virtual: true)

    timestamps(inserted_at: :inserted_at, updated_at: false)

    many_to_many(:interest_categories, BillBored.InterestCategory, join_through: "interest_categories_interests")
  end

  def changeset(interest, attrs) do
    interest
    |> cast(attrs, [:hashtag, :icon, :disabled?])
    |> validate_required([:hashtag, :disabled?])
    |> normalize()
    |> validate_length(:hashtag, min: 2, max: 35)
    |> validate_printable()
    |> unique_constraint(:hashtag, name: :interests_hashtag_index, message: "is already taken by other interest.")
    |> unique_constraint(:id, name: :interests_pkey, message: "must be unique.")
  end

  def update_changeset(interest, attrs \\ %{}) do
    interest
    |> cast(attrs, [:hashtag, :icon, :disabled?])
    |> normalize()
    |> validate_length(:hashtag, min: 2, max: 35)
    |> validate_printable()
    |> unique_constraint(:hashtag, name: :interests_hashtag_index, message: "is already taken by other interest.")
    |> unique_constraint(:id, name: :interests_pkey, message: "must be unique.")
  end

  defp validate_printable(changeset) do
    printable? =
      changeset
      |> get_field(:hashtag)
      |> String.printable?()

    unless printable? do
      add_error(changeset, :hashtag, "Hashtag has characters that are not printable!")
    end || changeset
  end

  def wrap(interest) when is_binary(interest) do
    %{"hashtag" => interest}
  end

  def wrap(interest), do: interest

  def normalize(%Ecto.Changeset{} = changeset) do
    value =
      changeset
      |> get_field(:hashtag)
      |> normalize()

    put_change(changeset, :hashtag, value)
  end

  def normalize(hashtag) do
    hashtag
    |> String.trim_leading("#")
    |> String.downcase()
    |> String.replace("#", " ")
    |> String.trim()
    |> String.replace(" ", "-")
    |> String.replace(~r/(-)+/, "-")
    |> String.trim_trailing("-")
  end

  def normalize_icon(icon) do
    icon
    |> String.replace(" ", "")
    |> String.trim()
    |> case do
      "" ->
        nil

      icon ->
        icon
    end
  end
end
