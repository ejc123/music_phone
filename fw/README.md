# MusicPhoneFw

This project is the firmware module for the music_phone application
## Targets

Currently a rpi0 is supported: `rpi0` 
Set `MIX_TARGET=rpi0`

For more information about targets see:

https://hexdocs.pm/nerves/targets.html#content

## WIFI setup

If you put your hardware in a box, it becomes tedious to swap out SD cards.
Nerves supports over-the-air updates with the ([ssh_subsystem_fwup](https://hex.pm/packages/ssh_subsystem_fwup)) 
package.  

Your hardware needs to support networking, and you need to set
some environment variables. 

`NERVES_NETWORK_SSID` is the SSID for the wireless network
`NERVES_NETWORK_PSK` is the shared secret for the wireless network

The mix configuration checks for these and will fail if they are not
set.

If you do not need wireless, you can set

`NERVES_NETWORK_NO_WIFI`

to ignore the wifi settings.


## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=rpi0` or prefix every command with
    `MIX_TARGET=pi0`. 
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`
