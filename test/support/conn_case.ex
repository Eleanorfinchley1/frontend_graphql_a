defmodule Web.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.
  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.
  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest, except: [connect: 2]

      alias Web.Router.Helpers, as: Routes

      import BillBored.Factory
      import Bureaucrat.Helpers

      # The default endpoint for testing
      @endpoint Web.Endpoint

      def authenticate(conn) do
        authenticate(conn, insert(:user))
      end

      def authenticate(conn, %BillBored.User{} = user) do
        authenticate(conn, insert(:auth_token, user: user))
      end

      def authenticate(conn, %BillBored.User.AuthToken{} = auth_token) do
        put_req_header(conn, "authorization", "Bearer #{auth_token.key}")
      end

      def authenticate(conn, token_key) when is_binary(token_key) do
        put_req_header(conn, "authorization", "Bearer #{token_key}")
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
