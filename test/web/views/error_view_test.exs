defmodule Web.ErrorViewTest do
  use Web.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(Web.ErrorView, "404.html", []) == "Page not found"
  end

  test "render 500.html" do
    assert render_to_string(Web.ErrorView, "500.html", []) == "Internal server error"
  end

  test "render 505.json" do
    assert render_to_string(Web.ErrorView, "505.json", []) ==
             ~s({"error":"Internal server error"})
  end

  test "render changeset.json" do
    {:error, %Ecto.Changeset{} = invalid_changeset} =
      BillBored.Livestreams.create(%{}, owner_id: nil)

    assert render(Web.ErrorView, "changeset.json", changeset: invalid_changeset) == %{
             "success" => false,
             "reason" => %{
               location: ["can't be blank"],
               owner_id: ["can't be blank"],
               title: ["can't be blank"]
             }
           }
  end
end
