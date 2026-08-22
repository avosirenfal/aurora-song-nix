# tl;dr;

When you want to change configuration or add/remove software edit nix and rebuild. Never edit non-nix configs directly because they will be overwritten. The server is using ZFS with compression enabled. **DO NOT RUN ZFS DATASET COMMANDS IF YOU AREN'T EXPERIENCED**!

# Useful commands

- `psql`: postgresql shell, root is a superuser and connects by default to the postgresql database
  - `\l`: list databases
  - `\c ss14_main`: connect to `ss14_main` db
  - `\d`: list tables
  - `\dt+`: list tables + filesize per table
  - `\d tablename`: describe schema for table `tablename`
- `nxr`: rebuild nixos, alias for `nixos-rebuild switch --flake /root/nixos#aurora`. will pass extra parameters like `--show-trace` if provided
- `rg`: [ripgrep](https://github.com/burntsushi/ripgrep) automatically using delta for syntax highlighting
- `rgo`: search all files in current directory using ripgrep and display results in-context with fzf. uses ripgrep options
- shortcut `control+r`: searchable history with atuin
- `systemctl list-units`: show all systemd units
- `systemctl cat unitname`: show systemd unit config for unit named `unitname`
- `journalctl -I unitname`: show logs only for the most recent invocation of `unitname`
- `nix flake update`: (while in `/root/nixos`) - update all packages by updating the nixpkgs-update revision in `flake.lock`. run `nxr` afterwards to actually rebuild!

# SS14 services

All SS14 related daemons run under systemd, so use `systemctl` to stop/start/restart/cat and `journalctl` to view logs.

The services are as follows:

  - watchdog: updates SS14 instance between restarts, restarts SS14 if it crashes or isn't responding. **SS14 servers are not killed if watchdog restarts!**
  - robust-cdn: receives publishes from CI, offers differential updates for players connecting, offers latest server files for watchdog. robust-cdn is not exposed publicly because it does not support SSL or HTTP/2
  - nginx: reverse proxies robust-cdn to the external CDN hostname (cdn.aurorasong.gay)
  - postgresql: SS14 database, which lives under ss14_main because main is the watchdog instance name for the server. `root` is already configured as a superuser!
  - prometheus: SS14 performance metric collection for grafana
  - loki: SS14 log aggregator for grafana

# Useful directories and files

- `/root/nixos`: Nix config, this is a jj repo currently
- Any state for systemd services lives in `/var/lib/servicename`, e.g. `/var/lib/watchdog`, etc.
- `/var/lib/secrets/ss14.nix`: secrets file with API keys and Discord webhooks, not part of the Nix config to keep secrets out of the Nix config repository, which is public.
- `/root/nixos/ss14-aurora.nix`: SS14 server config, from [this very repo](./ss14-aurora.nix)

# Nix stuff

- Rebuilding nixos (`nxr` or `nixos-rebuild switch ...`) will automatically restart systemd units that have changed
- Never modify files in the ss14 folder; these are nixos modules intended only to set sane defaults for *any* SS14 server. Aurora specific config belongs in [./ss14.nix](./ss14-nix)!
- All options in any Nix module are merged deterministically and lazy evaluated. There is no evaluation order. Think of Nix as roughly "JSON with functions"
