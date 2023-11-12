defmodule BillBored.Stubs.EventsProvider do
  def synchronize_events(_location), do: {:error, :recently_synced}
end
