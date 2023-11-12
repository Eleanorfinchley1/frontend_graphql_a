defmodule Repo.Migrations.CreateInterestHashtagTrgmIndex do
  use Ecto.Migration

  # TODO compare with an index on interest.name
  def up do
    execute(
      "create index interests_interest_hashtag_trgm_index on interests_interest using gin (hashtag gin_trgm_ops);"
    )
  end

  def down do
    execute("drop index interests_interest_hashtag_trgm_index;")
  end
end
