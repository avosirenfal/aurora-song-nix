{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.ss14-watchdog;
  format = pkgs.formats.yaml { };
  formatToml = pkgs.formats.toml { };
  ss14-packages = import ../packages/default.nix { inherit pkgs; };
  serviceName = config.services.ss14-watchdog.serviceName;
  dataDir = "/var/lib/${serviceName}";
  filterNulls = x: lib.filterAttrsRecursive (n: v: v != null) x;
in
{
  options.services.ss14-watchdog = {
    enable = mkEnableOption "Space Station 14 Watchdog server";

    package = mkOption {
      type = types.package;
      default = ss14-packages.ss14-watchdog;
      description = "The SS14.Watchdog package to use.";
    };

    serviceName = mkOption {
      type = types.str;
      default = "watchdog";
      description = "The name used for the SS14 systemd unit, user, and group.";
    };

    instances = mkOption {
      description = "Game server instances managed by the Watchdog.";
      default = { };
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              Name = mkOption {
                type = types.str;
                default = name;
                description = "Human-readable name of the instance, used in logging.";
              };

              ApiToken = mkOption {
                type = types.str;
                description = "API token for external access (e.g., to trigger updates or restarts).";
              };

              ApiPort = mkOption {
                type = types.port;
                description = ''
                  Port of the game server on localhost. Must match the HTTP status 
                  API port configured in the server's own config.
                '';
              };

              Settings = mkOption {
                type = types.submodule {
                  freeformType = formatToml.type;
                  options = import ../_internal/instance-options.nix {
                    inherit pkgs lib config;
                  };
                };
                description = "Server TOML config as Nix option set.";
              };

              # TODO: standardize casing because it's kinda fucked
              # some stuff is camelCase some stuff is PascalCase
              # but everything in .settings needs to be PascalCase
              # because those are the literal names for the config
              # files. honestly I probably should whip up a better
              # abstraction around mkOption than this stuff because
              # having no @SerialName nor sum types is pretty dismal
              ConfigFile = mkOption {
                type = types.path;
                default = formatToml.generate "config.toml" (filterNulls config.Settings);
                defaultText = literalMD "Generated from Settings.";
                description = ''
                  Path to the TOML config file for this instance. Defaults to a
                  file generated from Settings. Override to supply a raw file directly.
                '';
              };

              TimeoutSeconds = mkOption {
                type = types.ints.positive;
                default = 60;
                description = ''
                  Time in seconds the Watchdog waits for a ping from the server 
                  before assuming it crashed and forcefully restarting it.
                '';
              };

              DumpOnTimeout = mkOption {
                type = types.bool;
                default = false;
                description = "Save state data for analysis if a freeze/timeout occurs.";
              };

              RunCommand = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Override the executable/script used to run the server.";
              };

              EnvironmentVariables = mkOption {
                type = types.attrsOf types.str;
                default = { };
                example = {
                  ROBUST_NUMERICS_AVX = "true";
                };
                description = "Environment variables to pass to the game server instance.";
              };

              update = mkOption {
                description = "Update configuration. You must set exactly one of the available methods.";
                type = types.submodule {
                  options = {
                    manifest = mkOption {
                      description = "Manifest update method";
                      default = null;
                      type = types.nullOr (
                        types.submodule {
                          options = {
                            ManifestUrl = mkOption {
                              type = types.str;
                              example = "https://wizards.cdn.spacestation14.com/fork/wizards/manifest";
                              description = "URL to the version manifest JSON.";
                            };
                          };
                        }
                      );
                    };

                    git = mkOption {
                      description = "Git update method";
                      default = null;
                      type = types.nullOr (
                        types.submodule {
                          options = {
                            BaseUrl = mkOption {
                              type = types.str;
                              example = "https://github.com/moonheart08/outer-rim-14/";
                              description = "The URL of the Git repository to watch.";
                            };
                            Branch = mkOption {
                              type = types.str;
                              example = "master";
                              description = "The repository branch to watch.";
                            };
                            HybridACZ = mkOption {
                              type = types.bool;
                              default = false;
                              description = "Whether the game server hosts the client zip instead of the watchdog.";
                            };
                          };
                        }
                      );
                    };

                    jenkins = mkOption {
                      description = "Jenkins update method";
                      default = null;
                      type = types.nullOr (
                        types.submodule {
                          options = {
                            BaseUrl = mkOption {
                              type = types.str;
                              example = "http://localhost:9938";
                              description = "Jenkins base URL.";
                            };
                            JobName = mkOption {
                              type = types.str;
                              example = "Star";
                              description = "Jenkins job name to watch.";
                            };
                          };
                        }
                      );
                    };

                    dummy = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Fake an update whenever queried. Assumes server is pre-extracted.";
                    };
                  };
                };
              };
            };
          }
        )
      );
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = format.type;
        options = {
          BaseUrl = mkOption {
            type = types.str;
            default = "http://localhost:5000/";
            example = "https://builds.spacestation14.io/watchdog/";
            description = ''
              The external URL of the Watchdog. This is passed to instances automatically 
              so they can check in. Required for the game servers to communicate.
            '';
          };

          Urls = mkOption {
            type = types.str;
            default = "http://localhost:5000/";
            example = "http://*:5000";
            description = ''
              Controls which interfaces the Watchdog binds to. Watchdog should not be exposed
              without a reverse proxy.
            '';
          };

          AllowedHosts = mkOption {
            type = types.str;
            default = "*";
            description = "Valid host names clients may use to connect.";
          };

          Process = mkOption {
            type = types.submodule {
              freeformType = format.type;
              options = {
                PersistServers = mkOption {
                  type = types.bool;
                  default = false;
                  description = ''
                    If enabled, the watchdog will not shut down game servers when it is 
                    shut down, and will resume watching them on restart. This also sets 
                    `KillMode=process` in the systemd service.
                  '';
                };
              };
            };
            default = { };
            description = "Watchdog process configuration.";
          };

          Notification = mkOption {
            type = types.submodule {
              freeformType = format.type;
              options = {
                DiscordWebhook = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Discord webhook URL for server crash notifications.";
                };
              };
            };
            default = { };
            description = "Notification settings.";
          };
        };
      };
      default = { };
      description = ''
        Global watchdog settings, serialized to YAML. `$VAR` placeholders are supported 
        for secrets and will be expanded from `environmentFile`.
      '';
    };

    configFile = mkOption {
      type = types.path;
      default = format.generate "appsettings.yml" cfg.settings;
      defaultText = literalMD "Generated from [](#opt-services.ss14-watchdog.settings).";
      description = ''
        Path to the Watchdog config file. `$VAR` placeholders are expanded 
        with envsubst at startup if an `environmentFile` is provided.
      '';
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file containing secrets to substitute into `appsettings.yml`.";
      example = literalExpression "config.age.secrets.ss14-watchdog.path";
    };
  };

  config = mkIf cfg.enable {
    services.ss14-watchdog.settings.Servers.Instances = mapAttrs (
      name: inst:
      let
        updateType =
          if inst.update.manifest != null then
            "Manifest"
          else if inst.update.git != null then
            "Git"
          else if inst.update.jenkins != null then
            "Jenkins"
          else
            "Dummy";

        updatesPayload =
          if updateType == "Manifest" then
            inst.update.manifest
          else if updateType == "Git" then
            inst.update.git
          else if updateType == "Jenkins" then
            inst.update.jenkins
          else
            null;
      in
      # drop null values so they aren't serialized
      filterAttrs (n: v: v != null) {
        Name = inst.Name;
        ApiToken = inst.ApiToken;
        ApiPort = inst.ApiPort;
        TimeoutSeconds = inst.TimeoutSeconds;
        DumpOnTimeout = inst.DumpOnTimeout;
        RunCommand = inst.RunCommand;
        EnvironmentVariables = if inst.EnvironmentVariables != { } then inst.EnvironmentVariables else null;
        UpdateType = updateType;
        Updates = updatesPayload;
      }
    ) cfg.instances;

    assertions = flatten (
      mapAttrsToList (name: inst: {
        assertion =
          let
            count =
              (if inst.update.manifest != null then 1 else 0)
              + (if inst.update.git != null then 1 else 0)
              + (if inst.update.jenkins != null then 1 else 0)
              + (if inst.update.dummy then 1 else 0);
          in
          count == 1;
        message = "SS14 Watchdog instance '${name}' must have exactly one update method configured (manifest, git, jenkins, or dummy).";
      }) cfg.instances
    );

    users.users.${serviceName} = {
      isSystemUser = true;
      group = serviceName;
      home = dataDir;
      description = "SS14.Watchdog service user";
    };
    users.groups.${serviceName} = { };

    systemd.services.${serviceName} = {
      description = "Space Station 14 Watchdog server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      # TODO: the documentation says...
      # "This is used for git method to not fail instantly."
      # whatever that means, I guess because git runs under watchdog
      # and can't write outside the state directory and /tmp?
      environment = {
        DOTNET_CLI_HOME = "/tmp";
      };

      serviceConfig = {
        Type = "simple";
        User = serviceName;
        Group = serviceName;
        WorkingDirectory = dataDir;
        StateDirectory = serviceName;
        UMask = "0077";

        Restart = "on-failure";
        OOMPolicy = "continue";
        KillMode = mkIf cfg.settings.Process.PersistServers "process";

        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
        ExecStartPre =
          let
            mkConfig =
              srcFile: outDst:
              if cfg.environmentFile != null then
                ''${pkgs.envsubst}/bin/envsubst -i "${srcFile}" -o "${outDst}"''
              else
                ''ln -sf "${srcFile}" "${outDst}'';

            mkInstanceConfig = name: inst: ''
              mkdir -p "${dataDir}/instances/${name}"
              ${mkConfig inst.ConfigFile "${dataDir}/instances/${name}/config.toml"}
            '';
          in
          pkgs.writeShellScript "ss14-watchdog-prestart" ''
            ${mkConfig cfg.configFile "${dataDir}/appsettings.yml"}
            ${strings.concatLines (mapAttrsToList (name: inst: mkInstanceConfig name inst) cfg.instances)}
          '';

        ExecStart =
          let
            fhs = pkgs.buildFHSEnv {
              name = "ss14-watchdog-fhs";

              targetPkgs =
                pkgs: with pkgs; [
                  # .net runtime dependencies
                  zlib
                  icu
                  openssl
                  curl
                  libkrb5
                  lttng-ust

                  # ss14 dependencies
                  sqlite
                  freetype
                  fontconfig
                ];

              runScript = "${cfg.package}/bin/SS14.Watchdog";
            };
          in
          "${fhs}/bin/ss14-watchdog-fhs";

        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        LockPersonality = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
