Code.require_file("../../test_helper.exs", __DIR__)

defmodule TypeHelper do
  alias Module.Types
  alias Module.Types.{Pattern, Expr}

  defmacro quoted_expr(patterns \\ [], guards \\ [], body) do
    expr = expand_expr(patterns, guards, body, __CALLER__)

    quote do
      TypeHelper.__expr__(unquote(Macro.escape(expr)))
    end
  end

  def __expr__({patterns, guards, body}) do
    with {:ok, _types, context} <-
           Pattern.of_head(patterns, guards, new_stack(), new_context()),
         {:ok, type, context} <- Expr.of_expr(body, new_stack(), context) do
      {:ok, Types.lift_type(type, context)}
    else
      {:error, {type, reason, _context}} ->
        {:error, {type, reason}}
    end
  end

  defp expand_expr(patterns, guards, expr, env) do
    fun =
      quote do
        fn unquote(patterns) when unquote(guards) -> unquote(expr) end
      end

    {ast, _env} = :elixir_expand.expand(fun, env)
    {:fn, _, [{:->, _, [[{:when, _, [patterns, guards]}], body]}]} = ast
    {patterns, guards, body}
  end

  defp new_context() do
    Types.context("types_test.ex", TypesTest, {:test, 0}, [], Module.ParallelChecker.test_cache())
  end

  defp new_stack() do
    %{
      Types.stack()
      | last_expr: {:foo, [], nil}
    }
  end
end
