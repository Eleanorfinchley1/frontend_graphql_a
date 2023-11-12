defmodule Repo.Migrations.CreatePostContentTsvColumn do
  use Ecto.Migration

  def change do
    alter table(:pst_post) do
      add(:tsv, :tsvector)
    end

    create(index(:pst_post, [:tsv], name: :pst_post_body_tsvector_index, using: "GIN"))
  end
end
