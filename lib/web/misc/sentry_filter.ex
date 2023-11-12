defmodule Web.SentryFilter do
  @moduledoc false
  @behaviour Sentry.EventFilter

  @impl true
  def exclude_exception?(%Phoenix.Router.NoRouteError{}, :plug), do: true
  def exclude_exception?(_exception, _source), do: false
end
