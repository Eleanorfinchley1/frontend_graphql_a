defmodule BillBored.Admin.AuthTokens do
  @moduledoc ""
  import Bcrypt, only: [hash_pwd_salt: 1]


  # TODO can be a random string instead
  @salt hash_pwd_salt("admin")

  defp max_age_secs_by_status(status) do
    case status do
      "accepted" -> 3600
      "enabled" -> 3600
      _ -> 3600 * 24
    end
  end

  def generate(admin) do
    token_age_secs = max_age_secs_by_status(admin.status)
    Phoenix.Token.sign(Web.Endpoint, @salt, %{id: admin.id, status: admin.status, hash: admin.password}, max_age: token_age_secs)
  end

  def verify_payload(token) do
    with {:ok, %{id: _admin_id, status: status, hash: _hash}} <- Phoenix.Token.verify(Web.Endpoint, @salt, token) do
      token_age_secs = max_age_secs_by_status(status)
      Phoenix.Token.verify(Web.Endpoint, @salt, token, max_age: token_age_secs)
    end
  end
end
