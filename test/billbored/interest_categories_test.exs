defmodule BillBored.InterestCategoriesTest do
  use BillBored.DataCase, async: true

  alias BillBored.InterestCategory
  alias BillBored.InterestCategories

  describe "list_for_user/1" do
    setup do
      football = insert(:interest, hashtag: "football")
      hockey = insert(:interest, hashtag: "hockey")
      polo = insert(:interest, hashtag: "polo")

      sports = insert(:interest_category, name: "sports")

      for interest <- [football, hockey, polo] do
        insert(:interest_category_interest, interest: interest, interest_category: sports)
      end

      paris = insert(:interest, hashtag: "paris")
      berlin = insert(:interest, hashtag: "berlin")

      countries = insert(:interest_category, name: "countries")
      travel = insert(:interest_category, name: "travel")

      for interest <- [paris, berlin] do
        insert(:interest_category_interest, interest: interest, interest_category: countries)
        insert(:interest_category_interest, interest: interest, interest_category: travel)
      end

      burger = insert(:interest, hashtag: "burger")
      soup = insert(:interest, hashtag: "soup")
      meatloaf = insert(:interest, hashtag: "meatloaf")

      food = insert(:interest_category, name: "food")

      for interest <- [burger, soup, meatloaf] do
        insert(:interest_category_interest, interest: interest, interest_category: food)
        insert(:interest_category_interest, interest: interest, interest_category: travel)
      end

      cake = insert(:interest, hashtag: "cake")
      insert(:interest_category_interest, interest: cake, interest_category: food)

      [user1, user2, user3] = insert_list(3, :user)

      for interest <- [football, hockey, cake] do
        insert(:user_interest, user: user1, interest: interest)
      end

      insert(:user_interest, user: user2, interest: berlin)

      %{user1: user1, user2: user2, user3: user3}
    end

    test "returns correct categories for user1", %{user1: user1} do
      assert [%InterestCategory{name: "food"}, %InterestCategory{name: "sports"}] =
        InterestCategories.list_for_user(user1.id) |> Enum.sort_by(fn %{name: name} -> name end)
    end

    test "returns correct categories for user2", %{user2: user2} do
      assert [%InterestCategory{name: "countries"}, %InterestCategory{name: "travel"}] =
        InterestCategories.list_for_user(user2.id) |> Enum.sort_by(fn %{name: name} -> name end)
    end

    test "returns empty list for user3", %{user3: user3} do
      assert [] == InterestCategories.list_for_user(user3.id)
    end
  end
end
