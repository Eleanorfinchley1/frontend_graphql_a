defmodule BillBored.ServiceRegistry do
  @process_key :service_registry
  @application_key :billbored

  defmacro service(name) do
    if Mix.env() in [:prod] do
      quote do unquote(name) end
    else
      quote do
        name = unquote(name)
        case Process.get(unquote(@process_key)) do
          %{^name => value} -> value
          _ -> Application.get_env(unquote(@application_key), unquote(__MODULE__), []) |> Keyword.get(name, name)
        end
      end
    end
  end

  def replace(source, target) do
    case Code.ensure_compiled(target) do
      {:module, _module} ->
      case Process.get(@process_key) do
        nil -> Process.put(@process_key, %{source => target})
        %{} = stubs ->
          new_stubs = stubs |> Map.put(source, target)
          Process.put(@process_key, new_stubs)
      end
    _ ->
      raise CompileError, description: "Module #{target} isn't compiled"
    end
  end

  def reset(name) do
    case Process.get(@process_key) do
      %{^name => _} = stubs -> Process.put(@process_key, stubs |> Map.delete(name))
    end
  end
end
