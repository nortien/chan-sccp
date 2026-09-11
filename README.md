# chan-sccp

Cisco SCCP ("Skinny") channel driver for Asterisk, in the nortien fork line. SCCP is the protocol Cisco desk phones speak to a Cisco CallManager; this driver lets Asterisk answer them instead, so Cisco 79xx, 69xx and 89xx phones work on FreePBX 16 and 17 with no CallManager at all. New to the terms? The wiki has a [glossary](https://github.com/nortien/sccp_manager/wiki/Glossary).

**Current release: 4.4.0** · GUI companion: [nortien/sccp_manager](https://github.com/nortien/sccp_manager) · Documentation: [wiki](https://github.com/nortien/sccp_manager/wiki)

| | |
|---|---|
| Asterisk | compiles against 13 through 23; `./configure` detects the installed version by itself |
| Tested with phones | FreePBX 16 with Asterisk 20 and FreePBX 17 with Asterisk 23, on Sangoma's own FreePBX images: *sng7* is FreePBX 16 on a CentOS 7 base, *sng12* is FreePBX 17 on Debian 12 |
| Precompiled binaries | every release ships one `chan_sccp.so` per Asterisk major version and image, named `chan_sccp-ast<major>-<image>.so`: sng7 for Asterisk 18 and 20, sng12 for Asterisk 18, 20, 21, 22 and 23 |
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

Run this in a shell on the PBX (over SSH), as a user who can `sudo`. You need the Asterisk header files for the Asterisk you run (`asterisk -V` tells the version), a compiler and git:

```bash
# FreePBX 16 (Sangoma sng7, CentOS 7 base) - use asterisk18-devel or asterisk20-devel to match asterisk -V
sudo yum install asterisk20-devel gcc make git
# FreePBX 17 (Sangoma sng12, Debian 12 base) - asterisk18-, 20-, 21-, 22- or 23-devel to match asterisk -V
sudo apt install asterisk22-devel gcc make git
```

Then:

```bash
git clone https://github.com/nortien/chan-sccp.git
cd chan-sccp
./configure --enable-conference --enable-video
make -j"$(nproc)"
sudo make install
```

`./configure` finds your Asterisk version by itself. Everything most installs need is on by default: call park, pickup, directed transfer, feature buttons, speed dials with busy lamps, dialplan functions, the AMI interface. The two options above switch on the parts that are off by default:

| Option | What it does | Default |
|---|---|---|
| `--enable-conference` | Conferencing from the phone: the Conf softkey and the participant list. | off |
| `--enable-video` | Video calls between phones that support video (8945, 9971). Experimental; harmless on phones without a camera. | off |
| `--enable-advanced-functions` | Meant to add three extra softkeys, but none of them is finished upstream: Callback only shows "Key is not active", cBarge is unreachable code, and Transfer to Voicemail is already there in every build under the name `transvm`. The option changes nothing you can use either way. Leave it off; the 4.4.0 binaries were built with it, which makes no difference. | off |
| `--enable-distributed-devicestate` | Shared device state between Asterisk servers, for Asterisk 1.8 to 12 only. Does nothing on Asterisk 13 and later. | off |
| `--with-asterisk-version=22.0` | Pins the Asterisk version when several sets of headers are installed. | detected |
| `--with-asterisk=PATH`, `--with-astmoddir=PATH` | An Asterisk installed outside the usual places, and where to put the module. | detected |

`./configure --help` lists the rest; the [wiki page on building](https://github.com/nortien/sccp_manager/wiki/Building-and-Development) explains them.

`sudo make install` copies `chan_sccp.so` into Asterisk's module directory. If there is no `/etc/asterisk/sccp.conf` yet, it also installs a **sample configuration**. Read it before any phone can reach the PBX: the sample has Hotline switched on, which lets any phone on a private network register and dial a test extension, and it contains three example phones. Replace it with your own (start from `conf/sccp.conf.minimal`), or install the SCCP Manager module, which writes the file for you.

Finally make sure `/etc/asterisk/modules.conf` contains `noload = chan_skinny.so` (Asterisk's own old Skinny driver holds the same port and stops this one from starting), and restart Asterisk:

```bash
sudo fwconsole restart
```

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

Check the driver from the Asterisk console (on the PBX: `asterisk -r`, or one command at a time with `asterisk -rx "..."`):

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
