defmodule Web.Helpers do
  import Phoenix.Controller, only: [render: 3, put_view: 2]
  import BillBored.Helpers, only: [encode_base64_id: 2]
  alias Web.Router.Helpers, as: Routes

  def render_result(conn, result) do
    conn
    |> put_view(Web.LayoutView)
    |> render("success.json", result: result)
  end

  def universal_link(id, %{schema: schema}) do
    base64_id = encode_base64_id(id, %{schema: schema})

    case schema do
      BillBored.Livestream -> Routes.browser_livestream_url(Web.Endpoint, :show, base64_id)
      BillBored.Post -> Routes.browser_post_url(Web.Endpoint, :show, base64_id)
      BillBored.Event -> Routes.browser_event_url(Web.Endpoint, :show, base64_id)
    end
  end

  def validate_params(supported_params, params) do
    result =
      supported_params
      |> Enum.reduce_while({[], %{}}, fn
        {src_key, dst_key, required}, {missing, found} ->
          case params do
            %{^src_key => value} ->
              {:cont, {missing, Map.put(found, dst_key, value)}}

            _ ->
              if required do
                {:cont, {[src_key | missing], found}}
              else
                {:cont, {missing, found}}
              end
          end

        {src_key, dst_key, required, type}, {missing, found} ->
          case params do
            %{^src_key => value} ->
              case try_cast_to_type(value, type) do
                {:ok, value} -> {:cont, {missing, Map.put(found, dst_key, value)}}
                {:error, _} -> {:halt, {:error, :invalid_param_type}}
              end

            _ ->
              if required do
                {:cont, {[src_key | missing], found}}
              else
                {:cont, {missing, found}}
              end
          end
      end)

    case result do
      {[], %{} = found} ->
        {:ok, found}

      {missing, _} when is_list(missing) ->
        {:error, :missing_required_params, Enum.map_join(missing, ", ", &to_string(&1))}

      error ->
        error
    end
  end

  # Boolean
  defp try_cast_to_type(value, :boolean) when is_boolean(value), do: {:ok, value}
  defp try_cast_to_type("false", :boolean), do: {:ok, false}
  defp try_cast_to_type("true", :boolean), do: {:ok, false}
  defp try_cast_to_type(_, :boolean), do: {:error, :bad_boolean}

  # String
  defp try_cast_to_type(value, :string) when is_binary(value), do: {:ok, value}
  defp try_cast_to_type(_, :string), do: {:error, :bad_string}

  # Integer
  defp try_cast_to_type(value, :integer) when is_integer(value), do: {:ok, value}
  defp try_cast_to_type(value, :integer) when is_binary(value) do
    case Integer.parse(value) do
      {value, ""} -> {:ok, value}
      _ -> {:error, :bad_integer}
    end
  end
  defp try_cast_to_type(_, :integer), do: {:error, :bad_integer}

  # Number (float)
  defp try_cast_to_type(value, :number) when is_integer(value) or is_float(value), do: {:ok, value}
  defp try_cast_to_type(value, :number) when is_binary(value) do
    case Float.parse(value) do
      {value, ""} -> {:ok, value}
      _ -> {:error, :bad_number}
    end
  end
  defp try_cast_to_type(_, :number), do: {:error, :bad_number}

  # Array (list)
  defp try_cast_to_type(value, :array) when is_list(value), do: {:ok, value}
  defp try_cast_to_type(_, :array), do: {:error, :bad_array}
end
