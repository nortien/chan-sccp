# chan-sccp

Cisco SCCP (Skinny) channel driver for Asterisk — patched to build and run on Asterisk 18 through 23, for use with FreePBX 16/17.

**Companion GUI:** [nortien/sccp_manager](https://github.com/nortien/sccp_manager)

## Install (recommended)

The installer picks a precompiled binary for your Asterisk version if one exists, and compiles from source only if it doesn't:

```bash
curl -fsSLO https://raw.githubusercontent.com/nortien/sccp_manager/stable/scripts/install-chan-sccp-driver.sh
sudo bash install-chan-sccp-driver.sh
```

It detects your Asterisk version, installs the matching build dependencies, excludes `chan_skinny.so`, restarts Asterisk, and verifies the driver actually loaded.

## Build from source

If you'd rather build it yourself:

```bash
git clone https://github.com/nortien/chan-sccp.git
cd chan-sccp
./configure --enable-conference --enable-advanced-functions \
  --enable-distributed-devicestate --enable-video
make -j2
sudo make install
sudo fwconsole restart
```

`./configure` detects your Asterisk version on its own — no version flag needed. You need the matching `asterisk<major>-devel` package installed first, plus `gcc`, `make` and `git`.

## Update

```bash
git pull origin stable
./configure --enable-conference --enable-advanced-functions \
  --enable-distributed-devicestate --enable-video
make -j2
sudo make install
sudo fwconsole restart
```

Always a full `fwconsole restart` after `make install` — never hot-swap `chan_sccp.so` while Asterisk is running.

## Troubleshooting

- If `chan_skinny.so` is loaded, this driver won't fully initialize — exclude it in `modules.conf` first.
- If `./configure` fails, make sure the matching `asterisk<major>-devel` package is installed.
- Full guide: [Wiki](https://github.com/nortien/sccp_manager/wiki)

## Credits

Fork of [chan-sccp/chan-sccp](https://github.com/chan-sccp/chan-sccp) — all credit for the protocol implementation and driver architecture belongs to that project and its maintainers.

## License

GPL v3 — see `COPYING`.
