defmodule Fw.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Fw.Supervisor]
    children =
      [
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
    ]
  end

  def children(_target) do
    [
    ]
  end

  def target() do
    Application.get_env(:fw, :target)
  end
end
