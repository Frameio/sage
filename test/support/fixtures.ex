defmodule Sage.Fixtures do
  @moduledoc false
  alias Sage.EffectsAgent
  alias Sage.CounterAgent

  @max_random_sleep_timeout 5

  def transaction(effect) do
    test_pid = self()

    fn _effects_so_far, _opts ->
      random_sleep()
      EffectsAgent.push_effect!(effect, test_pid)
      {:ok, effect}
    end
  end

  def transaction_with_abort(effect) do
    test_pid = self()

    fn _effects_so_far, _opts ->
      random_sleep()
      EffectsAgent.push_effect!(effect, test_pid)
      {:abort, effect}
    end
  end

  def transaction_with_sleep(effect, timeout) do
    test_pid = self()

    fn _effects_so_far, _opts ->
      EffectsAgent.push_effect!(effect, test_pid)
      :timer.sleep(timeout)
      {:ok, effect}
    end
  end

  def transaction_with_error(effect) do
    test_pid = self()

    fn _effects_so_far, _opts ->
      random_sleep()
      EffectsAgent.push_effect!(effect, test_pid)
      {:error, effect}
    end
  end

  def transaction_with_exception(effect) do
    test_pid = self()

    fn _effects_so_far, _opts ->
      random_sleep()
      EffectsAgent.push_effect!(effect, test_pid)
      raise "error while creating #{to_string(effect)}"
    end
  end

  def transaction_with_throw(effect) do
    test_pid = self()

    fn _effects_so_far, _opts ->
      random_sleep()
      EffectsAgent.push_effect!(effect, test_pid)
      throw("error while creating #{to_string(effect)}")
    end
  end

  def transaction_with_exit(effect) do
    test_pid = self()

    fn _effects_so_far, _opts ->
      random_sleep()
      EffectsAgent.push_effect!(effect, test_pid)
      exit("error while creating #{to_string(effect)}")
    end
  end

  def transaction_with_n_errors(number_of_errors, effect) do
    test_pid = self()

    fn _effects_so_far, _opts ->
      random_sleep()
      EffectsAgent.push_effect!(effect, test_pid)

      if CounterAgent.get(number_of_errors) > 0 do
        CounterAgent.dec()
        {:error, effect}
      else
        {:ok, effect}
      end
    end
  end

  def transaction_with_malformed_return(effect) do
    test_pid = self()

    fn _effects_so_far, _opts ->
      random_sleep()
      EffectsAgent.push_effect!(effect, test_pid)
      {:bad_returns, :are_bad_mmmkay}
    end
  end

  def compensation(effect \\ nil) do
    test_pid = self()

    fn effect_to_compensate, _name_and_reason, _opts ->
      random_sleep()
      EffectsAgent.pop_effect!(effect || effect_to_compensate, test_pid)
      :ok
    end
  end

  def compensation_with_exception(effect \\ nil) do
    fn _effect_to_compensate, _name_and_reason, _opts ->
      random_sleep()
      raise "error while compensating #{to_string(effect)}"
    end
  end

  def compensation_with_throw(effect \\ nil) do
    fn _effect_to_compensate, _name_and_reason, _opts ->
      random_sleep()
      throw("error while compensating #{to_string(effect)}")
    end
  end

  def compensation_with_exit(effect \\ nil) do
    fn _effect_to_compensate, _name_and_reason, _opts ->
      random_sleep()
      exit("error while compensating #{to_string(effect)}")
    end
  end

  def compensation_with_malformed_return(effect \\ nil) do
    test_pid = self()

    fn effect_to_compensate, _name_and_reason, _opts ->
      random_sleep()
      EffectsAgent.pop_effect!(effect || effect_to_compensate, test_pid)
      {:bad_returns, :are_bad_mmmkay}
    end
  end

  def not_strict_compensation(effect \\ nil) do
    test_pid = self()

    fn effect_to_compensate, _name_and_reason, _opts ->
      random_sleep()
      EffectsAgent.delete_effect!(effect || effect_to_compensate, test_pid)
      :ok
    end
  end

  def compensation_with_retry(limit, effect \\ nil) do
    test_pid = self()

    fn effect_to_compensate, _name_and_reason, _opts ->
      random_sleep()
      EffectsAgent.pop_effect!(effect || effect_to_compensate, test_pid)
      {:retry, [retry_limit: limit]}
    end
  end

  def compensation_with_abort(effect \\ nil) do
    test_pid = self()

    fn effect_to_compensate, _name_and_reason, _opts ->
      random_sleep()
      EffectsAgent.pop_effect!(effect || effect_to_compensate, test_pid)
      :abort
    end
  end

  def compensation_with_circuit_breaker(effect \\ nil) do
    test_pid = self()

    fn effect_to_compensate, _name_and_reason, _opts ->
      random_sleep()
      EffectsAgent.pop_effect!(effect_to_compensate, test_pid)
      {:continue, effect || :"#{effect_to_compensate}_from_cache"}
    end
  end

  def lock(resource_name) do
    test_pid = self()

    fn opts ->
      random_sleep()
      EffectsAgent.push_effect!(:"lock_#{resource_name}", test_pid)
      send(test_pid, {:locked, resource_name})
      {:ok, resource_name}
    end
  end

  def unlock(resource_name \\ nil) do
    test_pid = self()

    fn locked_resource_name, _opts ->
      random_sleep()
      EffectsAgent.pop_effect!(resource_name || locked_resource_name, test_pid)
      :ok
    end
  end

  defp random_sleep do
    1..@max_random_sleep_timeout
    |> Enum.random()
    |> :timer.sleep()
  end
end
