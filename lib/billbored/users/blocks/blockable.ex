defmodule BillBored.User.Blockable do
  defmacro __using__(opts) do
    schema = __CALLER__.module
    foreign_key = Keyword.fetch!(opts, :foreign_key)

    quote do
      import Ecto.Query

      def not_blocked([for_id: for_id]) do
        not_blocked(%{for_id: for_id})
      end
      def not_blocked([for: %{id: for_id}]) do
        not_blocked(%{for_id: for_id})
      end
      def not_blocked(%{for: %{id: for_id}}) do
        not_blocked(%{for_id: for_id})
      end
      def not_blocked(%{for_id: for_id}) do
        from(q in unquote(schema),
         left_join: bl in BillBored.User.Block,
         on: (bl.to_userprofile_id == field(q, unquote(foreign_key)) and bl.from_userprofile_id == ^for_id) or
             (bl.from_userprofile_id == field(q, unquote(foreign_key)) and bl.to_userprofile_id == ^for_id),
         where: is_nil(bl.id)
        )
      end
      def not_blocked(_), do: unquote(schema)

      def join_blocked(queryable, for_id) do
        from(q in queryable,
         left_join: bl in BillBored.User.Block,
         on: (bl.to_userprofile_id == field(q, unquote(foreign_key)) and bl.from_userprofile_id == ^for_id) or
             (bl.from_userprofile_id == field(q, unquote(foreign_key)) and bl.to_userprofile_id == ^for_id),
         as: :blocked,
         select_merge: %{blocked?: not is_nil(bl.id)}
        )
      end
    end
  end
end
