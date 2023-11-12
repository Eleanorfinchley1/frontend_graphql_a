defmodule Web.Torch.AccessRestrictionPolicyController do
  use Web, :controller

  alias BillBored.KVEntries.AccessRestrictionPolicy

  plug(:put_layout, {Web.LayoutView, "torch.html"})

  def show(conn, _params) do
    render(conn, "show.html", %{access_restriction_policy: get!()})
  end

  def edit(conn, _params) do
    arp = get!()
    changeset = AccessRestrictionPolicy.Value.changeset(arp.value)
    render(conn, "edit.html", value: arp.value, changeset: changeset)
  end

  def update(conn, %{"value" => value} = _params) do
    arp = get!()

    case Repo.update(AccessRestrictionPolicy.changeset(arp, %{"value" => value})) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Access restriction policy updated successfully.")
        |> redirect(to: Routes.torch_access_restriction_policy_path(conn, :show))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", access_restriction_policy: arp, changeset: changeset)
    end
  end

  defp get!() do
    Repo.get!(AccessRestrictionPolicy, "access_restriction_policy")
  end
end
