defmodule Web.InterestControllerTest do
  use Web.ConnCase, async: true

  describe "index" do
    setup do
      [_sports, food, travel, alphabet] =
        [
          {"sports", "🏆"},
          {"food", "🍴"},
          {"travel", "✈️"},
          {"alphabet", "📚"}
        ]
        |> Enum.map(fn {name, icon} ->
          insert(:interest_category, name: name, icon: icon)
        end)

      [
        {"beer", "🍺", [food]},
        {"fine-dining", nil, [food]},
        {"europe", "🇪🇺", [travel]},
        {"rome", nil, [travel, food]},
        {"books", nil, [alphabet]}
      ] |> Enum.each(fn {name, icon, categories} ->
        interest = insert(:interest, hashtag: name, icon: icon)
        Enum.each(categories, fn category ->
          insert(:interest_category_interest, interest_category: category, interest: interest)
        end)
      end)

      :ok
    end

    test "lists all interests", %{conn: conn} do
      assert %{
        "entries" => [
          %{"disabled?" => false, "hashtag" => "beer", "icon" => "🍺"},
          %{"disabled?" => false, "hashtag" => "books", "icon" => "📚"},
          %{"disabled?" => false, "hashtag" => "europe", "icon" => "🇪🇺"},
          %{"disabled?" => false, "hashtag" => "fine-dining", "icon" => "🍴"},
          %{"disabled?" => false, "hashtag" => "rome", "icon" => "🍴"}
        ],
        "page_number" => 1,
        "page_size" => 10,
        "total_entries" => 5,
        "total_pages" => 1
      } =
        conn
        |> authenticate()
        |> get(Routes.interest_path(conn, :index))
        |> doc()
        |> json_response(200)
    end
  end

  describe "categories" do
    setup do
      [
        {"sports", "🏆"},
        {"food", "🍴"},
        {"travel", "✈️"},
        {"alphabet", "📚"}
      ]
      |> Enum.each(fn {name, icon} ->
        insert(:interest_category, name: name, icon: icon)
      end)
    end

    test "lists all interest categories", %{conn: conn} do
      assert [
               %{"name" => "alphabet", "icon" => "📚"},
               %{"name" => "food", "icon" => "🍴"},
               %{"name" => "sports", "icon" => "🏆"},
               %{"name" => "travel", "icon" => "✈️"}
             ] ==
               conn
               |> authenticate()
               |> get(Routes.interest_path(conn, :categories))
               |> doc()
               |> json_response(200)
    end
  end
end
