defmodule BillBored.Post.Comment do
  use BillBored, :schema
  use Arbor.Tree
  use BillBored.User.Blockable, foreign_key: :author_id

  alias BillBored.{Post, User, Interest, Upload}

  import Ecto.Changeset
  import BillBored.Helpers, only: [media_files_from_keys: 1]

  @type t :: %__MODULE__{}

  schema "posts_comments" do
    field(:body, :string)
    field(:disabled?, :boolean, default: false)

    many_to_many :media_files, Upload,
      join_through: "comment_uploads",
      join_keys: [comment_id: :id, upload_key: :media_key],
      on_replace: :delete

    field(:upvotes_count, :integer, default: 0, virtual: true)
    field(:downvotes_count, :integer, default: 0, virtual: true)

    field(:user_upvoted?, :boolean, default: false, virtual: true)
    field(:user_downvoted?, :boolean, default: false, virtual: true)

    field(:blocked?, :boolean, default: false, virtual: true)

    field :children, {:array, :map}, virtual: true

    belongs_to(:post, Post)
    belongs_to(:author, User)
    belongs_to(:parent, __MODULE__)

    many_to_many(:interests, Interest, join_through: Post.Comment.Interest, on_replace: :delete)

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  def available(params) do
    from(c in not_blocked(params),
      inner_join: a in assoc(c, :author),
      where: a.banned? == false and a.deleted? == false
    )
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [
      :body,
      :disabled?,
      :post_id,
      :parent_id
    ])
    |> put_assoc(:media_files, media_files_from_keys(attrs["media_file_keys"] || []))
    |> validate_required([:post_id, :body])
    |> validate_length(:body, max: 512)
    |> foreign_key_constraint(:parent_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:author_id)
  end
end
