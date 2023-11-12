defmodule Repo.Migrations.AddClappingToDropchatStreamsReactions do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE user_reaction_type_enum_temp AS ENUM ('like', 'dislike', 'clapping')")
    execute("ALTER TABLE dropchat_streams_reactions ALTER COLUMN type TYPE user_reaction_type_enum_temp USING type::text::user_reaction_type_enum_temp")
    execute("DROP TYPE user_reaction_type_enum")
    execute("ALTER TYPE user_reaction_type_enum_temp RENAME TO user_reaction_type_enum")
  end

  def down do
    execute("CREATE TYPE user_reaction_type_enum_temp AS ENUM ('like', 'dislike')")
    execute("ALTER TABLE dropchat_streams_reactions ALTER COLUMN type TYPE user_reaction_type_enum_temp USING type::text::user_reaction_type_enum_temp")
    execute("DROP TYPE user_reaction_type_enum")
    execute("ALTER TYPE user_reaction_type_enum_temp RENAME TO user_reaction_type_enum")
  end
end
