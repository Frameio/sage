defmodule Sage.TestCompensationErrorHandler do
  @moduledoc false
  @behaviour Sage.CompensationErrorHandler

  def handle_error({:exception, %Sage.MalformedCompensationReturnError{}, _stacktrace}, compensations_to_run, opts) do
    all_effects = all_effects(compensations_to_run)

    :ok =
      compensations_to_run
      |> List.delete_at(0)
      |> Enum.each(fn {_name, compensation, effect_to_compensate} when is_function(compensation, 3) ->
        apply(Sage.Fixtures.not_strict_compensation(), [effect_to_compensate, all_effects, opts])
      end)

    {:error, :failed_to_compensate_errors}
  end

  def handle_error(_error, compensations_to_run, opts) do
    all_effects = all_effects(compensations_to_run)

    :ok =
      Enum.each(compensations_to_run, fn {_name, compensation, effect_to_compensate} when is_function(compensation, 3) ->
        apply(Sage.Fixtures.not_strict_compensation(), [effect_to_compensate, all_effects, opts])
      end)

    {:error, :failed_to_compensate_errors}
  end

  defp all_effects(compensations_to_run) do
    for {name, _compensation, effect} <- compensations_to_run, do: {name, effect}, into: %{}
  end
end
