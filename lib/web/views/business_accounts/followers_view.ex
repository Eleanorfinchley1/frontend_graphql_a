defmodule Web.BusinessAccounts.FollowersView do
  use Web, :view

  def render("history.json", %{history: history}) do
    %{
      history: history
    }
  end
end
