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

  instanceGroup = key: port: rec {
    instances = filterAttrs (n: v: v.${key}) cfg.instances;
    hasAny = instances != { };
    names = sort (a: b: a < b) (attrNames instances);
    # map instance names to monotonically increasing unique ports (44880, 44881, ...)
    ports =
      if port != null then listToAttrs (imap0 (i: name: nameValuePair name (port + i)) names) else null;
    portFor = name: ports.${name};
  };

  postgres = instanceGroup "postgres" null;
  prometheus = instanceGroup "prometheus" 44880;
  loki = instanceGroup "loki" null;
in
{
  options.services.ss14-servers = {
    enable = mkEnableOption "Space Station 14 Servers";

    instances = mkOption {
      description = "SS14 instances";
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
                  Use a local PostgreSQL instance for player slot and preference
                  database instead of SQLite.
                '';
              };

              prometheus = mkOption {
                type = types.bool;
                default = false;
                description = "Whether to use a local Prometheus instance for performance metrics.";
              };

              loki = mkOption {
                type = types.bool;
                default = false;
                description = "Whether to push logs to a local Loki instance.";
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
          # status.bind = "${inst.bindIp}:${toString inst.port}";
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
            port = prometheus.portFor name;
          };
        }
        // optionalAttrs inst.loki {
          loki = {
            enabled = true;
            address = "http://localhost:3100";
            name = name;
          };
        }
      );
    }) cfg.instances;

    services.postgresql = mkIf postgres.hasAny {
      enable = true;
      ensureDatabases = mapAttrsToList (n: _: "ss14_${n}") postgres.instances;
      ensureUsers = mapAttrsToList (n: _: {
        name = "ss14_${n}";
        ensureDBOwnership = true;
      }) postgres.instances;

      authentication =
        let
          dbUsers = concatStringsSep "," (mapAttrsToList (n: _: "ss14_${n}") postgres.instances);
        in
        ''
          # type database  user        auth-method
          local  all       ${dbUsers}  peer map=ss14map
        '';
      identMap =
        let
          # watchdog spawns game instances so they run as ss14-watchdog
          # let watchdog system user access db instance for any ss14
          # postgres account
          mappings = mapAttrsToList (
            n: _: "ss14map ${config.services.ss14-watchdog.serviceName} ss14_${n}"
          ) postgres.instances;
        in
        concatStringsSep "\n" mappings;
    };

    services.loki = mkIf loki.hasAny {
      enable = true;
      configuration = {
        auth_enabled = false;

        server = {
          http_listen_port = 3100;
        };

        common = {
          instance_addr = "127.0.0.1";
          path_prefix = "/var/lib/loki";
          replication_factor = 1;
          ring = {
            kvstore.store = "inmemory";
          };
        };

        schema_config = {
          configs = [
            {
              from = "2024-01-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-index";
            cache_location = "/var/lib/loki/tsdb-cache";
          };
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          retention_enabled = true;
          delete_request_store = "filesystem";
        };

        limits_config = {
          retention_period = "30d";
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        # not sure what this is or whether ss14 uses it
        # ruler.alertmanager_url = "http://localhost:9093";
      };
    };

    services.prometheus = mkIf prometheus.hasAny {
      enable = true;
      scrapeConfigs = mapAttrsToList (name: inst: {
        job_name = name;
        static_configs = [
          {
            targets = [
              "localhost:${toString (prometheus.portFor name)}"
            ];
          }
        ];
      }) prometheus.instances;
    };
  };
}
