defmodule Iodized.DefinitionJson do
  defprotocol Json do
    def to_json(definition)
  end

  def from_json(nil) do
    nil
  end

  def from_json(definition) do
    operand = Dict.fetch!(definition, :operand)
    from_json(operand, definition)
  end

  defp from_json("any", definition), do: composite_from_json(Iodized.Definition.Any, definition)
  defimpl Json, for: Iodized.Definition.Any do
    def to_json(any) do
      %{operand: "any", definitions: Enum.map(any.definitions || [], &Json.to_json(&1))}
    end
  end

  defp from_json("all", definition), do: composite_from_json(Iodized.Definition.All, definition)
  defimpl Json, for: Iodized.Definition.All do
    def to_json(all) do
      %{operand: "all", definitions: Enum.map(all.definitions || [], &Json.to_json(&1))}
    end
  end

  defp from_json("included_in", definition) do
    actual_state_param_name = Dict.fetch!(definition, :param_name)
    allowed_values = Dict.fetch!(definition, :value)
    true = is_list(allowed_values) # validate we've got a list
    Iodized.Definition.IncludedIn[actual_state_param_name: actual_state_param_name, allowed_values: allowed_values]
  end
  defimpl Json, for: Iodized.Definition.IncludedIn do
    def to_json(included_in) do
      %{operand: "included_in",
        param_name: included_in.actual_state_param_name,
        value: included_in.allowed_values}
    end
  end

  defp from_json("is", definition) do
    actual_state_param_name = Dict.fetch!(definition, :param_name)
    allowed_value = Dict.fetch!(definition, :value)
    Iodized.Definition.Is[actual_state_param_name: actual_state_param_name, allowed_value: allowed_value]
  end
  defimpl Json, for: Iodized.Definition.Is do
    def to_json(is) do
      %{operand: "is", param_name: is.actual_state_param_name, value: is.allowed_value}
    end
  end

  defp from_json("percentage", definition) do
    actual_state_param_name = Dict.fetch!(definition, :param_name)
    threshold = Dict.fetch!(definition, :value)
    Iodized.Definition.Percentage[
      actual_state_param_name: actual_state_param_name,
      threshold: binary_to_integer(threshold),
    ]
  end
  defimpl Json, for: Iodized.Definition.Percentage do
    def to_json(percentage) do
      %{
        operand: "percentage",
        param_name: percentage.actual_state_param_name,
        value: percentage.threshold,
      }
    end
  end

  defp composite_from_json(record_type, definition) do
    #TODO HAX because old JS admin uses wrong param name s/conditions/definitions/
    definitions = Dict.get(definition, :conditions) || Dict.fetch!(definition, :definitions)
    record_type.new(definitions: Enum.map(definitions, &from_json/1))
  end

  defimpl Json, for: Atom do
    def to_json(true), do: %{operand: "boolean", value: true}
    def to_json(false), do: %{operand: "boolean", value: false}
    def to_json(nil), do: nil
  end
end
