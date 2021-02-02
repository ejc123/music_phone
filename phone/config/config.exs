import Config
config :phone, target: Mix.target()

config :logger, backends: [RingLogger], level: :info
