defmodule Web.Torch.BusinessAccountController do
  use Web, :controller

  alias BillBored.Torch.BusinessAccounts, as: TorchBusinessAccounts

  plug(:put_layout, {Web.LayoutView, "torch.html"})

  def index(conn, params) do
    with {:ok, assigns} <- TorchBusinessAccounts.paginate_business_accounts(params) do
      render(conn, "index.html", assigns)
    else
      error ->
        conn
        |> put_flash(:error, "There was an error rendering Business Accounts. #{inspect(error)}")
        |> redirect(to: Routes.torch_business_account_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id}) do
    business_account = TorchBusinessAccounts.get_business_account!(id)
    render(conn, "show.html", business_account: business_account)
  end

  def edit(conn, %{"id" => id}) do
    business_account = TorchBusinessAccounts.get_business_account!(id)
    changeset = Ecto.Changeset.change(business_account)
    render(conn, "edit.html", business_account: business_account, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => attrs}) do
    business_account = TorchBusinessAccounts.get_business_account!(id)
    with {:ok, updated_business_account} <- TorchBusinessAccounts.update_business_account(business_account, attrs) do
      render(conn, "show.html", business_account: updated_business_account)
    else
      {:error, %Ecto.Changeset{valid?: false} = changeset} ->
        render(conn, "edit.html", business_account: business_account, changeset: changeset)

      error ->
        conn
        |> put_flash(:error, "There was an error updating Business Account: #{inspect(error)}")
        |> redirect(to: Routes.torch_business_account_path(conn, :edit, id))
    end
  end
end
