defmodule BillBored.Helpers do
  @moduledoc "Contains various helpers"

  def replace_null(list_object) when is_list(list_object) do
    Enum.map(list_object, &replace_null(&1))
  end

  def replace_null(object) do
    object
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
      {k, v || ""}
    end)
    |> Enum.into(%{})
  end

  # TODO: think of a better way
  def normalize(%{invited_count: nil} = record) do
    normalize(Map.put(record, :invited_count, 0))
  end

  def normalize(%{refused_count: nil} = record) do
    normalize(Map.put(record, :refused_count, 0))
  end

  def normalize(%{accepted_count: nil} = record) do
    normalize(Map.put(record, :accepted_count, 0))
  end

  def normalize(%{doubts_count: nil} = record) do
    normalize(Map.put(record, :doubts_count, 0))
  end

  def normalize(%{missed_count: nil} = record) do
    normalize(Map.put(record, :missed_count, 0))
  end

  def normalize(%{presented_count: nil} = record) do
    normalize(Map.put(record, :presented_count, 0))
  end

  def normalize(%{upvotes_count: nil} = record) do
    normalize(Map.put(record, :upvotes_count, 0))
  end

  def normalize(%{downvotes_count: nil} = record) do
    normalize(Map.put(record, :downvotes_count, 0))
  end

  def normalize(%{comments_count: nil} = record) do
    normalize(Map.put(record, :comments_count, 0))
  end

  def normalize(%{user_downvoted?: nil} = record) do
    normalize(Map.put(record, :user_downvoted?, false))
  end

  def normalize(%{user_upvoted?: nil} = record) do
    normalize(Map.put(record, :user_upvoted?, false))
  end

  def normalize(record), do: record

  @doc """
  Presents errors in a human readable way

      {:error, %Ecto.Changeset{} = changeset} = BillBored.Users.create(%{handle: "taken"})
      %{handle: ["has already been taken"]} = humanize_errors(changeset)

  """
  @spec humanize_errors(Ecto.Changeset.t()) :: %{atom => [binary]}
  def humanize_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  @spec media_files_from_keys([String.t()]) :: [%BillBored.Upload{}]
  def media_files_from_keys([]), do: []

  def media_files_from_keys(media_file_keys) when is_list(media_file_keys) do
    import Ecto.Query

    BillBored.Upload
    |> where([u], u.media_key in ^media_file_keys)
    |> Repo.all()

    # Enum.map(media_file_keys, &%BillBored.Upload{media_key: &1})
  end

  defp pkey_type(schema) do
    [pkey] = schema.__schema__(:primary_key)
    schema.__schema__(:type, pkey)
  end

  def encode_base64_id(id, %{schema: schema}) do
    schema
    |> pkey_type()
    |> _encode_base64(id)
  end

  def decode_base64_id(base64_id, %{schema: schema}) do
    schema
    |> pkey_type()
    |> _decode_base64(base64_id)
  end

  defp _encode_base64(:id, id) do
    id
    |> :erlang.integer_to_binary()
    |> Base.url_encode64(padding: false)
  end

  defp _encode_base64(Ecto.UUID, uuid) do
    uuid
    |> ensure_human_readable_uuid()
    |> Base.url_encode64(padding: false)
  end

  defp _decode_base64(:id, base64_id) do
    base64_id
    |> Base.url_decode64!(padding: false)
    |> :erlang.binary_to_integer()
  end

  defp _decode_base64(Ecto.UUID, base64_uuid) do
    base64_uuid
    |> Base.url_decode64!(padding: false)
    |> ensure_human_readable_uuid()
  end

  defp ensure_human_readable_uuid(uuid) do
    case uuid do
      <<_::36-bytes>> -> uuid
      <<_::16-bytes>> -> cast_uuid(uuid)
    end
  end

  defp cast_uuid(<<uuid::16-bytes>>) do
    {:ok, <<_::36-bytes>> = uuid} = Ecto.UUID.cast(uuid)
    uuid
  end
end
