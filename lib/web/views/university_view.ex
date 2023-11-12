defmodule Web.UniversityView do
  use Web, :view

  defp signed(university, field) do
    case picture = Map.get(university, field) do
      "http" <> _ -> picture
      "" -> picture
      _ ->
        expires_at = :os.system_time(:seconds) + 10 * 60 * 60
        Signer.create_signed_url(
          "GET",
          expires_at,
          "/#{System.get_env("GS_MEDIA_BUCKET_NAME")}/#{picture}"
        )
    end
  end

  def render("index.json", %{universities: universities}) do
    %{data: render_many(universities, Web.UniversityView, "university.json")}
  end

  def render("show.json", %{university: university}) do
    %{data: render_one(university, Web.UniversityView, "university.json")}
  end

  def render("university.json", %{university: university}) do
    %{
      id: university.id,
      name: university.name,
      country: university.country,
      allowed: university.allowed,
      avatar: signed(university, :avatar),
      avatar_thumbnail: signed(university, :avatar_thumbnail),
      icon: university.icon
    }
  end

  def render("university_points.json", %{university: university}) do
    %{
      id: university.id,
      name: university.name,
      country: university.country,
      allowed: university.allowed,
      avatar: signed(university, :avatar),
      avatar_thumbnail: signed(university, :avatar_thumbnail),
      icon: university.icon,
      tatal_points: university.total_points / 10,
      semester_points: university.semester_points / 10,
      monthly_points: university.monthly_points / 10,
      weekly_points: university.weekly_points / 10,
      daily_points: university.daily_points / 10
    }
  end
end
