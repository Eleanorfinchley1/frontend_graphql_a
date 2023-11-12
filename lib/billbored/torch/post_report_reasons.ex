defmodule BillBored.Torch.PostReportReasons do
  @moduledoc """
  The Torch.PostReportReasons context.
  """

  import Ecto.Query, warn: false
  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias BillBored.PostReportReason

  @pagination [page_size: 15]
  @pagination_distance 5

  @doc """
  Paginate the list of post_report_reasons using filtrex
  filters.

  ## Examples

      iex> list_post_report_reasons(%{})
      %{post_report_reasons: [%PostReportReason{}], ...}
  """
  @spec paginate_post_report_reasons(map) :: {:ok, map} | {:error, any}
  def paginate_post_report_reasons(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <- Filtrex.parse_params(filter_config(:post_report_reasons), params["post_report_reason"] || %{}),
        %Scrivener.Page{} = page <- do_paginate_post_report_reasons(filter, params) do
      {:ok,
        %{
          post_report_reasons: page.entries,
          page_number: page.page_number,
          page_size: page.page_size,
          total_pages: page.total_pages,
          total_entries: page.total_entries,
          distance: @pagination_distance,
          sort_field: sort_field,
          sort_direction: sort_direction
        }
      }
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate_post_report_reasons(filter, params) do
    PostReportReason
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  @doc """
  Returns the list of post_report_reasons.

  ## Examples

      iex> list_post_report_reasons()
      [%PostReportReason{}, ...]

  """
  def list_post_report_reasons do
    Repo.all(PostReportReason)
  end

  @doc """
  Gets a single post_report_reason.

  Raises `Ecto.NoResultsError` if the Post report reason does not exist.

  ## Examples

      iex> get_post_report_reason!(123)
      %PostReportReason{}

      iex> get_post_report_reason!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post_report_reason!(id), do: Repo.get!(PostReportReason, id)

  @doc """
  Creates a post_report_reason.

  ## Examples

      iex> create_post_report_reason(%{field: value})
      {:ok, %PostReportReason{}}

      iex> create_post_report_reason(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post_report_reason(attrs \\ %{}) do
    %PostReportReason{}
    |> PostReportReason.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post_report_reason.

  ## Examples

      iex> update_post_report_reason(post_report_reason, %{field: new_value})
      {:ok, %PostReportReason{}}

      iex> update_post_report_reason(post_report_reason, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post_report_reason(%PostReportReason{} = post_report_reason, attrs) do
    post_report_reason
    |> PostReportReason.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PostReportReason.

  ## Examples

      iex> delete_post_report_reason(post_report_reason)
      {:ok, %PostReportReason{}}

      iex> delete_post_report_reason(post_report_reason)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post_report_reason(%PostReportReason{} = post_report_reason) do
    Repo.delete(post_report_reason)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post_report_reason changes.

  ## Examples

      iex> change_post_report_reason(post_report_reason)
      %Ecto.Changeset{source: %PostReportReason{}}

  """
  def change_post_report_reason(%PostReportReason{} = post_report_reason) do
    PostReportReason.changeset(post_report_reason, %{})
  end

  defp filter_config(:post_report_reasons) do
    defconfig do
      number :id
      text :reason
    end
  end
end
