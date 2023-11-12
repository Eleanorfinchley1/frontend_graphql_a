defmodule Web.TopicView do
  use Web, :view



  def render("show.json", %{topic: topic}) do
    %{data: render_many(topic.meta, __MODULE__, "meta.json", as: :meta)}
  end



  def render("meta.json", %{meta: meta}) do
    %{topics: meta.topics, university_name: meta.university_name}
  end
end