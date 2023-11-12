defmodule BillBored.Notifications.AreaNotifications.MatchData do
  alias BillBored.User
  alias BillBored.Notifications.AreaNotification

  defstruct [:categories_set, :sex, :min_birthdate, :max_birthdate, :birthdate]

  def new(%AreaNotification{} = area_notification) do
    %__MODULE__{
      categories_set: prepare_categeries_set(area_notification.categories),
      sex: prepare_sex(area_notification.sex),
      min_birthdate: prepare_birthdate(area_notification.max_age),
      max_birthdate: prepare_birthdate(area_notification.min_age)
    }
  end

  def new(%User{} = user) do
    %__MODULE__{
      categories_set: prepare_user_categories(user),
      sex: prepare_sex(user.sex),
      birthdate: user.birthdate
    }
  end

  defp prepare_user_categories(%User{id: user_id}) do
    case BillBored.InterestCategories.list_for_user(user_id) do
      [] ->
        nil

      categories ->
        Enum.map(categories, &(&1.id)) |> MapSet.new()
    end
  end

  defp prepare_categeries_set(nil), do: nil
  defp prepare_categeries_set(categories) do
    BillBored.InterestCategories.list(categories)
    |> Enum.map(&(&1.id))
    |> MapSet.new()
  end

  defp prepare_sex(nil), do: nil
  defp prepare_sex(""), do: nil
  defp prepare_sex(value), do: String.upcase(value)

  defp prepare_birthdate(nil), do: nil
  defp prepare_birthdate(years), do: Timex.shift(Timex.today(), [{:years, -years}])

  def matches?(%__MODULE__{} = match_data, %__MODULE__{} = user_data) do
    matches_categories?(match_data.categories_set, user_data.categories_set)
      and matches_sex?(match_data.sex, user_data.sex)
      and matches_birthdate?(match_data.min_birthdate, user_data.birthdate, [0, 1])
      and matches_birthdate?(match_data.max_birthdate, user_data.birthdate, [-1, 0])
  end

  defp matches_categories?(nil, _), do: true
  defp matches_categories?(_, nil), do: false
  defp matches_categories?(expected_set, actual_sex) do
    intersection = MapSet.intersection(expected_set, actual_sex)
    MapSet.size(intersection) > 0
  end

  defp matches_sex?(nil, _), do: true
  defp matches_sex?(_, nil), do: false
  defp matches_sex?(expected_sex, actual_sex),
    do: expected_sex == String.upcase(actual_sex)

  defp matches_birthdate?(nil, _, _), do: true
  defp matches_birthdate?(_, nil, _), do: false
  defp matches_birthdate?(expected_birthdate, actual_birthdate, actual_cmp) do
    Timex.compare(actual_birthdate, expected_birthdate) in actual_cmp
  end
end
