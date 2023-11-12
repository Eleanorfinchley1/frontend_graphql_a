defmodule BillBored.Businesses do
  def get_all_categories(last_seen_param, direction_param) do
    BillBored.BusinessCategories.all_business_accounts(last_seen_param, direction_param)
  end

  def add_categories_to_business([], _user_id), do: {:ok, []}

  def add_categories_to_business(categories_to_add, user_id) do
    Enum.each(categories_to_add, fn category_to_add ->
      if BillBored.BusinessCategories.check_business_category_in_account(
           category_to_add["business_category_id"],
           user_id
         ) == nil do
        category = %BillBored.BusinessesCategories{
          business_category_id: category_to_add["business_category_id"],
          user_id: user_id
        }

        BillBored.BusinessCategories.add_category_to_business(category)
      end
    end)
  end
end
