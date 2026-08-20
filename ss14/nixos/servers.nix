{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.ss14-servers;
  formatToml = pkgs.formats.toml { };

  pgInstances = filterAttrs (n: v: v.postgres) cfg.instances;
  promInstances = filterAttrs (n: v: v.prometheus) cfg.instances;

  anyPostgres = pgInstances != { };
  anyPrometheus = promInstances != { };

  # map instance names to monotonically increasing unique ports (44880, 44881, ...)
  promInstanceNames = sort (a: b: a < b) (attrNames promInstances);
  promPorts = listToAttrs (imap0 (i: name: nameValuePair name (44880 + i)) promInstanceNames);
in
{
  options.services.ss14-servers = {
    enable = mkEnableOption "Space Station 14 Servers";

    instances = mkOption {
      default = { };
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              name = mkOption {
                type = types.str;
                default = name;
                description = "Name of the instance.";
              };

              bindIp = mkOption {
                type = types.str;
                default = "0.0.0.0";
                description = "IP address to bind the server to.";
              };

              port = mkOption {
                type = types.port;
                default = 1212;
                description = "Port for both UDP netcode and TCP status API.";
              };

              postgres = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Use PostgreSQL for player slot and preference
                  database instead of SQLite.
                '';
              };

              prometheus = mkOption {
                type = types.bool;
                default = false;
                description = "Whether to use Prometheus for performance metrics.";
              };

              manifestUrl = mkOption {
                type = types.str;
                example = "https://wizards.cdn.spacestation14.com/fork/wizards/manifest";
                description = "URL to the version manifest for this server.";
              };

              Settings = mkOption {
                type = types.submodule {
                  freeformType = formatToml.type;
                  options = import ../_internal/instance-options.nix { inherit lib config pkgs; };
                };
                default = { };
                description = "Server TOML config.";
              };

              ConfigFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = ''
                  Override the generated config.toml directly. Note this will
                  supercede automatically configured options like Postgres and
                  Prometheus integration.
                '';
              };
            };
          }
        )
      );
    };
  };

  config = mkIf cfg.enable {
    services.ss14-watchdog.enable = true;
    services.ss14-watchdog.instances = mapAttrs (name: inst: {
      Name = inst.name;
      ApiPort = inst.port;

      update.manifest.ManifestUrl = inst.manifestUrl;

      ConfigFile = mkIf (inst.ConfigFile != null) inst.ConfigFile;

      Settings = recursiveUpdate inst.Settings (
        {
          net.port = inst.port;
          status.bind = "${inst.bindIp}:${toString inst.port}";
        }
        // optionalAttrs inst.postgres {
          database = {
            engine = "postgres";
            pg_host = "/run/postgresql";
            pg_database = "ss14_${name}";
            pg_username = "ss14_${name}";
          };
        }
        // optionalAttrs inst.prometheus {
          metrics = {
            enabled = true;
            host = "localhost";
            port = promPorts.${name};
          };
        }
      );
    }) cfg.instances;

    services.postgresql = mkIf anyPostgres {
      enable = true;
      ensureDatabases = mapAttrsToList (n: _: "ss14_${n}") pgInstances;
      ensureUsers = mapAttrsToList (n: _: {
        name = "ss14_${n}";
        ensureDBOwnership = true;
      }) pgInstances;

      authentication =
        let
          dbUsers = concatStringsSep "," (mapAttrsToList (n: _: "ss14_${n}") pgInstances);
        in
        ''
          # type database  user        auth-method
          local  all       ${dbUsers}  peer map=ss14map

          local  all       all         trust
          host   all       all         127.0.0.1/32 trust
          host   all       all         ::1/128      trust
        '';
      identMap =
        let
          # watchdog spawns game instances so they run as ss14-watchdog
          # let watchdog system user access db instance for any ss14
          # postgres account
          mappings = mapAttrsToList (n: _: "ss14map ss14-watchdog ss14_${n}") pgInstances;
        in
        concatStringsSep "\n" mappings;
    };

    services.prometheus = mkIf anyPrometheus {
      enable = true;
      scrapeConfigs = mapAttrsToList (name: inst: {
        job_name = name;
        static_configs = [
          {
            targets = [
              "localhost:${toString promPorts.${name}}"
            ];
          }
        ];
      }) promInstances;
    };
  };
}
