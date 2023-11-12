defmodule BillBored.Notifications.AreaNotifications.MatchDataTest do
  use BillBored.DataCase, async: true

  alias BillBored.Notifications.AreaNotifications.MatchData
  alias BillBored.Notifications.AreaNotification

  defp match_data(categories, sex, min_age, max_age) do
    category_names =
      if !is_nil(categories) do
        Enum.map(categories, & &1.name)
      else
        nil
      end

    MatchData.new(%AreaNotification{
      categories: category_names,
      sex: sex,
      min_age: min_age,
      max_age: max_age
    })
  end

  describe "matches? without categories" do
    setup [:create_others, :create_females, :create_males]

    test "returns correct match when match data is empty", %{
      noone: noone,
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony
    } do
      match_data = match_data(nil, nil, nil, nil)

      for user <- [noone, katie, julie, annie, becky, jack, john, matt, tony] do
        assert MatchData.matches?(match_data, MatchData.new(user))
      end
    end

    test "returns correct match by age 18 to 24", %{
      noone: noone,
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony
    } do
      match_data = match_data(nil, nil, 18, 42)

      for user <- [julie, annie, john, matt] do
        assert MatchData.matches?(match_data, MatchData.new(user))
      end

      for user <- [noone, katie, becky, jack, tony] do
        refute MatchData.matches?(match_data, MatchData.new(user))
      end
    end

    test "returns correct match by age 18 to 24 female only", %{
      noone: noone,
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony
    } do
      match_data = match_data(nil, "F", 18, 42)

      for user <- [julie, annie] do
        assert MatchData.matches?(match_data, MatchData.new(user))
      end

      for user <- [noone, katie, becky, jack, tony, john, matt] do
        refute MatchData.matches?(match_data, MatchData.new(user))
      end
    end

    test "returns correct match by age 18 to 24 male only", %{
      noone: noone,
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony
    } do
      match_data = match_data(nil, "M", 18, 42)

      for user <- [john, matt] do
        assert MatchData.matches?(match_data, MatchData.new(user))
      end

      for user <- [noone, katie, becky, jack, tony, julie, annie] do
        refute MatchData.matches?(match_data, MatchData.new(user))
      end
    end

    test "returns correct match by age less than 18", %{
      noone: noone,
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony
    } do
      match_data = match_data(nil, nil, nil, 18)

      for user <- [katie, julie, jack] do
        assert MatchData.matches?(match_data, MatchData.new(user))
      end

      for user <- [noone, annie, becky, john, matt, tony] do
        refute MatchData.matches?(match_data, MatchData.new(user))
      end
    end

    test "returns correct match by age less than 18 female only", %{
      noone: noone,
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony
    } do
      match_data = match_data(nil, "F", nil, 18)

      for user <- [katie, julie] do
        assert MatchData.matches?(match_data, MatchData.new(user))
      end

      for user <- [noone, annie, becky, jack, john, matt, tony] do
        refute MatchData.matches?(match_data, MatchData.new(user))
      end
    end

    test "returns correct match by age less than 18 male only", %{
      noone: noone,
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony
    } do
      match_data = match_data(nil, "M", nil, 18)

      for user <- [jack] do
        assert MatchData.matches?(match_data, MatchData.new(user))
      end

      for user <- [noone, katie, julie, annie, becky, john, matt, tony] do
        refute MatchData.matches?(match_data, MatchData.new(user))
      end
    end

    test "returns correct match by age greater than 42", %{
      noone: noone,
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony
    } do
      match_data = match_data(nil, nil, 42, nil)

      for user <- [annie, becky, tony] do
        assert MatchData.matches?(match_data, MatchData.new(user))
      end

      for user <- [noone, katie, julie, jack, john, matt] do
        refute MatchData.matches?(match_data, MatchData.new(user))
      end
    end

    test "returns correct match by age greater than 42 female only", %{
      noone: noone,
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony
    } do
      match_data = match_data(nil, "F", 42, nil)

      for user <- [annie, becky] do
        assert MatchData.matches?(match_data, MatchData.new(user))
      end

      for user <- [noone, katie, julie, jack, john, matt, tony] do
        refute MatchData.matches?(match_data, MatchData.new(user))
      end
    end

    test "returns correct match by age greater than 42 male only", %{
      noone: noone,
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony
    } do
      match_data = match_data(nil, "M", 42, nil)

      for user <- [tony] do
        assert MatchData.matches?(match_data, MatchData.new(user))
      end

      for user <- [noone, katie, julie, annie, becky, jack, john, matt] do
        refute MatchData.matches?(match_data, MatchData.new(user))
      end
    end
  end

  describe "matches? with interest categories" do
    setup [:create_females, :create_males, :create_categories]

    test "returns correct match by categories", %{
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony,
      food: food,
      sports: sports
    } do
      match_data_food = match_data([food], nil, nil, nil)
      match_data_sports = match_data([sports], nil, nil, nil)

      for user <- [katie, julie, matt, tony] do
        refute MatchData.matches?(match_data_food, MatchData.new(user))
        assert MatchData.matches?(match_data_sports, MatchData.new(user))
      end

      for user <- [annie, becky, jack, john] do
        assert MatchData.matches?(match_data_food, MatchData.new(user))
        refute MatchData.matches?(match_data_sports, MatchData.new(user))
      end
    end

    test "returns correct match by age and categories", %{
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony,
      sports: sports,
      travel: travel
    } do
      match_data_sports = match_data([sports], nil, 18, 42)

      for user <- [katie, annie, becky, jack, john, tony] do
        refute MatchData.matches?(match_data_sports, MatchData.new(user))
      end

      for user <- [julie, matt] do
        assert MatchData.matches?(match_data_sports, MatchData.new(user))
      end

      match_data_travel = match_data([travel], nil, 18, 42)

      for user <- [katie, julie, annie, becky, jack, john, matt, tony] do
        refute MatchData.matches?(match_data_travel, MatchData.new(user))
      end
    end

    test "returns correct match by age, sex and categories", %{
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky,
      jack: jack,
      john: john,
      matt: matt,
      tony: tony,
      food: food
    } do
      match_data_food_f = match_data([food], "F", 18, 42)
      match_data_food_m = match_data([food], "M", 18, 42)

      for user <- [katie, julie, becky, jack, matt, tony] do
        refute MatchData.matches?(match_data_food_f, MatchData.new(user))
        refute MatchData.matches?(match_data_food_m, MatchData.new(user))
      end

      assert MatchData.matches?(match_data_food_f, MatchData.new(annie))
      refute MatchData.matches?(match_data_food_f, MatchData.new(john))
      assert MatchData.matches?(match_data_food_m, MatchData.new(john))
      refute MatchData.matches?(match_data_food_m, MatchData.new(annie))
    end
  end

  def create_others(_context) do
    noone =
      insert(:user, username: "noone", sex: "", birthdate: nil)

    %{
      noone: noone
    }
  end

  def create_females(_context) do
    katie =
      insert(:user, sex: "F", username: "katie", birthdate: Timex.shift(Timex.today(), years: -15))

    julie =
      insert(:user, sex: "F", username: "julie", birthdate: Timex.shift(Timex.today(), years: -18))

    annie =
      insert(:user, sex: "F", username: "annie", birthdate: Timex.shift(Timex.today(), years: -42))

    becky =
      insert(:user, sex: "F", username: "becky", birthdate: Timex.shift(Timex.today(), years: -56))

    %{
      katie: katie,
      julie: julie,
      annie: annie,
      becky: becky
    }
  end

  def create_males(_context) do
    jack =
      insert(:user, sex: "M", username: "jack", birthdate: Timex.shift(Timex.today(), years: -16))

    john =
      insert(:user, sex: "M", username: "john", birthdate: Timex.shift(Timex.today(), years: -22))

    matt =
      insert(:user, sex: "M", username: "matt", birthdate: Timex.shift(Timex.today(), years: -38))

    tony =
      insert(:user, sex: "M", username: "tony", birthdate: Timex.shift(Timex.today(), years: -66))

    %{
      jack: jack,
      john: john,
      matt: matt,
      tony: tony
    }
  end

  def create_categories(%{
        katie: katie,
        julie: julie,
        annie: annie,
        becky: becky,
        jack: jack,
        john: john,
        matt: matt,
        tony: tony
      }) do
    football = insert(:interest, hashtag: "football")
    hockey = insert(:interest, hashtag: "hockey")
    polo = insert(:interest, hashtag: "polo")

    sports = insert(:interest_category, name: "sports")

    for interest <- [football, hockey, polo] do
      insert(:interest_category_interest, interest: interest, interest_category: sports)
    end

    paris = insert(:interest, hashtag: "paris")
    berlin = insert(:interest, hashtag: "berlin")

    travel = insert(:interest_category, name: "travel")

    for interest <- [paris, berlin] do
      insert(:interest_category_interest, interest: interest, interest_category: travel)
    end

    burger = insert(:interest, hashtag: "burger")
    soup = insert(:interest, hashtag: "soup")
    meatloaf = insert(:interest, hashtag: "meatloaf")

    food = insert(:interest_category, name: "food")

    for interest <- [burger, soup, meatloaf] do
      insert(:interest_category_interest, interest: interest, interest_category: food)
    end

    for {user, interest} <- [
          {katie, football},
          {julie, polo},
          {annie, soup},
          {becky, burger},
          {jack, burger},
          {john, meatloaf},
          {matt, hockey},
          {tony, hockey}
        ] do
      insert(:user_interest, user: user, interest: interest)
    end

    %{
      sports: sports,
      food: food,
      travel: travel,
      football: football,
      hockey: hockey,
      polo: polo,
      paris: paris,
      berlin: berlin,
      burger: burger,
      soup: soup,
      meatloaf: meatloaf
    }
  end
end
