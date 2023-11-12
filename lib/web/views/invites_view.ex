defmodule Web.InvitesView do
  use Web, :view

  def render("index.json", %{invites: invites}) do
    render_many(invites, __MODULE__, "invite.json")
  end

  def render("invite.json", %{invites: invites}) do
    %{
      email: invites.email,
      user: invites.user_id
    }
  end
end
