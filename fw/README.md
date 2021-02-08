# MusicPhoneFw

This project is the firmware module for the music_phone application
## Targets

Currently a rpi0 is supported: `rpi0` 
Set `MIX_TARGET=rpi0`

For more information about targets see:

https://hexdocs.pm/nerves/targets.html#content

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=rpi0` or prefix every command with
    `MIX_TARGET=pi0`. 
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`
