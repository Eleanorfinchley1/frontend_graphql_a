defmodule BillBored.Period do
  def semester(now \\ DateTime.utc_now()) do
    year = now.year
    month = now.month

    st_month = div(month - 1, 4) * 4 + 1
    ed_month = st_month + 4

    {:ok, start_dt, 0} = DateTime.from_iso8601("#{year}-#{String.pad_leading(to_string(st_month), 2, "0")}-01T00:00:00Z")

    {:ok, end_dt, 0} = if ed_month > 12 do
      DateTime.from_iso8601("#{year + 1}-01-01T00:00:00Z")
    else
      DateTime.from_iso8601("#{year}-#{String.pad_leading(to_string(ed_month), 2, "0")}-01T00:00:00Z")
    end

    {start_dt, end_dt}
  end

  def month(now \\ DateTime.utc_now()) do
    year = now.year

    st_month = now.month
    ed_month = st_month + 1

    {:ok, start_dt, 0} = DateTime.from_iso8601("#{year}-#{String.pad_leading(to_string(st_month), 2, "0")}-01T00:00:00Z")

    {:ok, end_dt, 0} = if ed_month > 12 do
      DateTime.from_iso8601("#{year + 1}-01-01T00:00:00Z")
    else
      DateTime.from_iso8601("#{year}-#{String.pad_leading(to_string(ed_month), 2, "0")}-01T00:00:00Z")
    end

    {start_dt, end_dt}
  end

  def week(now \\ DateTime.utc_now()) do
    st_date = now |> DateTime.to_date()
    st_date = Date.add(st_date, - (Date.day_of_week(st_date) - 1))
    ed_date = Date.add(st_date, 7)

    {:ok, start_dt, 0} = DateTime.from_iso8601("#{Date.to_string(st_date)}T00:00:00Z")
    {:ok, end_dt, 0} = DateTime.from_iso8601("#{Date.to_string(ed_date)}T00:00:00Z")

    {start_dt, end_dt}
  end

  def today(now \\ DateTime.utc_now()) do
    st_date = now |> DateTime.to_date()
    ed_date = Date.add(st_date, 1)

    {:ok, start_dt, 0} = DateTime.from_iso8601("#{Date.to_string(st_date)}T00:00:00Z")
    {:ok, end_dt, 0} = DateTime.from_iso8601("#{Date.to_string(ed_date)}T00:00:00Z")

    {start_dt, end_dt}
  end
end
