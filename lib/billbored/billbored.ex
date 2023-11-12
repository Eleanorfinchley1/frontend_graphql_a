defmodule BillBored do
  @moduledoc false

  @type attrs :: %{binary => term} | %{atom => term}

  defmacro __using__(:schema) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      # to comply with django
      @timestamps_opts [inserted_at: :created, updated_at: :updated, type: :utc_datetime_usec]
    end
  end
end
