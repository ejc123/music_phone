import Config

# Set your .wav files, max calls per time
# period and the time period (in seconds) here

normal = System.get_env("NORMAL_WAV")
limited =  System.get_env("LIMITED_WAV")

if normal == nil,
do:
  Mix.raise("""
  You have not set a normal WAV file
  """)

if limited == nil,
do:
  Mix.raise("""
  You have not set a limited WAV file
  """)

config :phone, target: Mix.target(),
  normalWav: normal,
  limitWav: limited,
  limit: 2,
  time: 8*3600

config :logger, backends: [RingLogger], level: :info
