defmodule BillBored.User.AuthTokens do
  @moduledoc "manages auth tokens in authtoken_token table"
  alias BillBored.User.AuthToken

  @spec get_by_key(String.t()) :: AuthToken.t() | nil
  def get_by_key(token_key) do
    AuthToken
    |> Repo.get_by(key: token_key)
    |> Repo.preload(:user)
  end

  def get_by_user(user) do
    AuthToken
    |> Repo.get_by(user_id: user.id)
    |> Repo.preload(:user)
  end

  def create(user, token) do
    attrs = %{key: token, user_id: user.id}

    %AuthToken{}
    |> AuthToken.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Check if user already has a token, if not create a new token and store in database
  """
  def sign_in(user) do
    auth_token = get_by_user(user)

    if auth_token do
      {:ok, auth_token.key}
    else
      token = generate(user)
      create(user, token)
      {:ok, token}
    end
  end

  # TODO can be a random string instead
  def generate(user) do
    Phoenix.Token.sign(Web.Endpoint, "user", user.id)
  end
end
