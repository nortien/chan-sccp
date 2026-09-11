# chan-sccp

Cisco SCCP ("Skinny") channel driver for Asterisk, in the nortien fork line. It runs Cisco 79xx, 89xx and 99xx desk phones on FreePBX 16 and 17 without a CallManager.

**Current release: 4.4.0** · GUI companion: [nortien/sccp_manager](https://github.com/nortien/sccp_manager) · Documentation: [wiki](https://github.com/nortien/sccp_manager/wiki)

| | |
|---|---|
| Asterisk | compiles against 13 through 23; `./configure` detects the installed version by itself |
| Tested with phones | FreePBX 16 / Asterisk 20 (Sangoma sng7) and FreePBX 17 / Asterisk 23 (Sangoma sng12) |
| Precompiled binaries | every release ships `chan_sccp-ast<major>-<distro>.so` for sng7 (Asterisk 18, 20) and sng12 (Asterisk 18, 20, 21, 22, 23) |
| Reviewed | two full security and correctness reviews in 2026, see [Changes vs upstream](https://github.com/nortien/sccp_manager/wiki/Changes-vs-Upstream) |

## Install

### With the FreePBX module (recommended)

Install [sccp_manager](https://github.com/nortien/sccp_manager#install). Its release tarball bundles the driver binaries and its installer script puts the right one in place, offline.

### Driver only, on an existing FreePBX

```bash
curl -fsSLO https://raw.githubusercontent.com/nortien/sccp_manager/stable/scripts/install-chan-sccp-driver.sh
sudo bash install-chan-sccp-driver.sh
```

The script reads the Asterisk version and the distro, downloads the matching binary from the [latest release](https://github.com/nortien/chan-sccp/releases/latest), and compiles from source only when no binary matches. It then excludes `chan_skinny.so`, restarts Asterisk with `fwconsole restart` and checks that `sccp show version` answers.

### From source

You need the Asterisk headers (`asterisk<major>-devel` from the Sangoma repositories, or the headers of your own Asterisk build), plus `gcc`, `make` and `git`. No autotools are needed: `configure` is committed.

```bash
git clone https://github.com/nortien/chan-sccp.git
cd chan-sccp
./configure --enable-conference --enable-advanced-functions \
  --enable-distributed-devicestate --enable-video
make -j"$(nproc)"
sudo make install
```

Then make sure `/etc/asterisk/modules.conf` contains `noload = chan_skinny.so` and restart Asterisk:

```bash
sudo fwconsole restart
```

Useful configure options:

- `--with-asterisk-version=20.0` pins the version when several sets of headers are installed.
- `--with-asterisk=PATH` and `--with-astmoddir=PATH` for an Asterisk outside the usual prefix.

## Update

Re-run the installer script, which picks the newest release binary, or from a source checkout:

```bash
git pull origin stable
./configure --enable-conference --enable-advanced-functions \
  --enable-distributed-devicestate --enable-video
make -j"$(nproc)"
sudo make install
sudo fwconsole restart
```

Always restart Asterisk after `make install`. Never copy a new `chan_sccp.so` over the loaded one.

## Configuration

The driver reads `/etc/asterisk/sccp.conf`. With sccp_manager the file is written from the GUI. Without it, start from `conf/sccp.conf.minimal` or the annotated `conf/sccp.conf`, and see the [sccp.conf reference](https://github.com/nortien/sccp_manager/wiki/sccp.conf-options) in the wiki.

Check the driver from the Asterisk CLI:

```
sccp show version
sccp show devices
sccp show lines
```

## Troubleshooting

- The driver loads but no phone registers: `chan_skinny.so` is probably loaded and owns TCP port 2000. Exclude it and restart.
- `./configure` cannot find Asterisk: install the matching `asterisk<major>-devel` package, or point `--with-asterisk` at your prefix.
- A phone keeps rebooting or stays unprovisioned: that is TFTP and `SEP<MAC>.cnf.xml`, not the driver. See [Troubleshooting](https://github.com/nortien/sccp_manager/wiki/Troubleshooting) in the wiki.

## Development

`./tools/bootstrap.sh` regenerates `configure` after changes to `configure.ac` or `autoconf/*.m4`. Releases are built by [GitHub Actions](.github/workflows/build-release.yml) for the sng12 targets; the sng7 binaries are built on real sng7 machines and attached by hand. See [Building from source and development](https://github.com/nortien/sccp_manager/wiki/Building-and-Development) in the wiki.

## Credits

Fork of [chan-sccp/chan-sccp](https://github.com/chan-sccp/chan-sccp). The protocol implementation and the driver architecture are the work of that project and its maintainers; see `AUTHORS`.

## License

GNU General Public License, see `LICENSE`.
