# FlightBot - ADS-B Receiver

A Home Assistant app that turns an RTL-SDR stick (such as the RadarBox
FlightStick) plugged into the Home Assistant host into an ADS-B receiver.

It is a thin wrapper around
[sdr-enthusiasts/docker-adsb-ultrafeeder](https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder),
which bundles `readsb` (decoder) and `tar1090` (map). The only addition is
`rootfs/etc/s6-overlay/startup.d/00-ha-options`, which turns the app options
into the environment variables ultrafeeder expects.

## Install

1. Add `https://github.com/njyjn/ha-addons` as an app repository in Home Assistant.
2. Install **FlightBot**, plug in the stick, and start the app.
3. Open the web UI (host port `8090`) for the tar1090 map.

## Options

| Option | Default | Notes |
|---|---|---|
| `latitude`, `longitude`, `altitude_m` | Home Assistant home location | Antenna position; used for range and distance |
| `local_sdr` | `true` | Set `false` when the stick is on another device and data comes in via `ultrafeeder_config` |
| `gain` | `auto` | readsb built-in autogain; or a fixed dB value |
| `device_serial` | unset | Only needed with more than one RTL-SDR attached |
| `ppm` | unset | Frequency correction |
| `enable_aircraft_db` | `true` | Adds registration and type to `aircraft.json` (~50 MB RAM) |
| `history_days` | `1` | Days of track and heatmap history to keep in `/data/globe_history`; purged daily |
| `ultrafeeder_config` | unset | Raw `ULTRAFEEDER_CONFIG` string for feeding aggregators |

## Remote receiver

To put the stick at a window on a separate small device (for example a Pi Zero
running only `readsb`), set `local_sdr: false` and
`ultrafeeder_config: "adsb,<receiver-ip>,30005,beast_in"`. The map, graphs and
Home Assistant sensors then use the remote data. Only decoded messages cross
the network (a few kB/s), so 2.4 GHz Wi-Fi is enough.

## Storage

Track history, heatmaps, readsb state and the graphs1090 database live in the
app's `/data` folder, so they survive restarts and updates and are included in
Home Assistant backups. Dated history is purged after `history_days`;
graphs1090 uses fixed-size round-robin files that do not grow.

## Ports

| Container | Host | Purpose |
|---|---|---|
| `80/tcp` | `8090` | Map, and `http://<host>:8090/data/aircraft.json` |
| `30005/tcp` | disabled | Beast output, for feeders such as RadarBox |
| `30003/tcp` | disabled | SBS/BaseStation output |

## Home Assistant sensor

```yaml
rest:
  - resource: http://<host>:8090/data/aircraft.json
    scan_interval: 10
    sensor:
      - name: ADS-B aircraft count
        value_template: "{{ value_json.aircraft | length }}"
```

## Troubleshooting

- `usb_claim_interface error` in the log: the kernel DVB driver holds the
  stick. The bundled librtlsdr detaches it automatically, so this should be
  rare; replug the stick and restart the app.
- No aircraft: check antenna placement first. Indoors, range is much shorter.

## Release

Bump `version` in `config.yaml` on `main`. The release workflow builds
`ghcr.io/njyjn/flightbot` and notifies `njyjn/ha-addons`, which needs the
`HA_ADDONS_PAT` repository secret.
