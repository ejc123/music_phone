import Config

# Set your .wav files, max calls per time
# period and the time period (in seconds) here

config :phone, target: Mix.target(),
  normalWav: System.get_env("NORMAL_WAV"),
  limitWav: System.get_env("LIMITED_WAV"),
  limit: 2,
  time: 8*3600

config :logger, backends: [RingLogger], level: :info
