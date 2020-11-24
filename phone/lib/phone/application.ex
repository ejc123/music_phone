defmodule Phone.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define children
    children = [
      Phone.Board,
      Phone.Listener,
      Phone.GPS,
    ]

    opts = [strategy: :one_for_one, name: Phone.Supervisor]
    Supervisor.start_link(children, opts)
    Nerves.Runtime.validate_firmware()
  end
end
