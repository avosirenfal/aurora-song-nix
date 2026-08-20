{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.robust-cdn;
  format = pkgs.formats.json { };
  ss14-packages = import ../packages/default.nix { inherit pkgs; };
  dataDir = "/var/lib/robust-cdn"; # systemd StateDirectory creates this
in
{
  options.services.robust-cdn = {
    enable = mkEnableOption "Space Station 14 Robust.CDN server";

    package = mkOption {
      type = types.package;
      default = ss14-packages.robust-cdn;
      description = "The Robust.CDN package to use.";
    };

    port = mkOption {
      type = types.port;
      default = 27690;
      description = "Local port Robust.CDN listens on behind nginx.";
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = format.type;
        options = {
          Logging = mkOption {
            type = types.submodule {
              freeformType = format.type;
              options = {
                LogLevel = mkOption {
                  type = types.submodule {
                    freeformType = format.type;
                    options =
                      let
                        logLevelEnum = types.enum [
                          "Trace"
                          "Debug"
                          "Information"
                          "Warning"
                          "Error"
                          "Critical"
                          "None"
                        ];
                      in
                      {
                        Default = mkOption {
                          type = logLevelEnum;
                          default = "Information";
                          description = "Default log level.";
                        };
                        # TODO: make this AspNetCore and rewrite to "Microsoft.AspNetCore" before generate
                        "Microsoft.AspNetCore" = mkOption {
                          type = logLevelEnum;
                          default = "Warning";
                          description = "Log level for Microsoft.AspNetCore.";
                        };
                        Robust = mkOption {
                          type = logLevelEnum;
                          default = "Information";
                          description = "Log level for Robust.";
                        };
                      };
                  };
                  default = { };
                  description = "Log level configuration.";
                };
              };
            };
            default = { };
            description = "Logging configuration. The defaults are usually sufficient.";
          };

          Manifest = mkOption {
            type = types.submodule {
              freeformType = format.type;
              options = {
                FileDiskPath = mkOption {
                  type = types.path;
                  default = "${dataDir}/builds";
                  description = "Location on disk where builds are stored.";
                };
                DatabaseFileName = mkOption {
                  type = types.path;
                  default = "${dataDir}/manifest.db";
                  description = "SQLite database file for server manifest functionality.";
                };
                Forks = mkOption {
                  type = types.attrsOf (
                    types.submodule {
                      freeformType = format.type;
                      options = {
                        UpdateToken = mkOption {
                          type = types.str;
                          description = ''
                            API key used to publish new versions to this fork. This should be
                            a unique secret value.
                          '';
                        };
                        NotifyWatchdogs = mkOption {
                          type = types.listOf (
                            types.submodule {
                              freeformType = format.type;
                              options = {
                                WatchdogUrl = mkOption {
                                  type = types.str;
                                  description = "Base address of the SS14.Watchdog instance.";
                                };
                                Instance = mkOption {
                                  type = types.str;
                                  description = "Server instance name on the watchdog to notify.";
                                };
                                ApiToken = mkOption {
                                  type = types.str;
                                  description = "ApiToken from the watchdog config for this instance.";
                                };
                              };
                            }
                          );
                          default = [ ];
                          description = "Watchdogs to notify when a new build is published.";
                        };
                        Private = mkOption {
                          type = types.bool;
                          default = false;
                          description = ''
                            Make this a private fork (restricts access to server builds).
                            Useful for servers with secret content.
                          '';
                        };
                        PrivateUsers = mkOption {
                          type = types.attrsOf types.str;
                          default = { };
                          description = ''
                            Username -> password map for accessing private fork server files.
                            Ignored unless `Private = true`.
                          '';
                        };
                        PruneBuildsDays = mkOption {
                          type = types.ints.positive;
                          default = 90;
                          description = "How many days to keep old build files.";
                        };
                        DisplayName = mkOption {
                          type = types.str;
                          description = ''
                            Human-readable display name of this fork, shown on
                            the HTML builds page.
                          '';
                        };
                        BuildsPageLink = mkOption {
                          type = types.str;
                          default = null;
                          description = "Link destination on the HTML builds page.";
                        };
                        BuildsPageLinkText = mkOption {
                          type = types.str;
                          default = null;
                          description = "Link text on the HTML builds page.";
                        };
                      };
                    }
                  );
                  default = { };
                  description = ''
                    Available forks that Robust.Cdn should serve.
                    The attribute name is the fork ID, and should be globally unique.
                  '';
                };
              };
            };
            default = { };
            description = "Configuration for server manifest operations and available forks.";
          };

          Cdn = mkOption {
            type = types.submodule {
              freeformType = format.type;
              options = {
                DatabaseFileName = mkOption {
                  type = types.path;
                  default = "${dataDir}/content.db";
                  description = ''
                    SQLite database file for client CDN / content downloads.
                  '';
                };
                StreamCompressLevel = mkOption {
                  type = types.ints.between 0 9;
                  default = 5;
                  description = ''
                    Compression level for streamed downloads.
                    Higher values reduce bandwidth but use more CPU.
                  '';
                };
                DefaultFork = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = ''
                    Fallback fork used for migration from Robust.Cdn 1.x.
                    Can be omitted on new installations.
                  '';
                };
              };
            };
            default = { };
            description = "Client CDN configuration.";
          };

          BaseUrl = mkOption {
            type = types.str;
            example = "https://cdn.myfork.com";
            description = ''
              Publicly available root URL for Robust.Cdn.
            '';
          };

          PathBase = mkOption {
            type = types.str;
            default = "/";
            example = "/cdn/";
            description = ''
              The URL subpath Robust.Cdn is exposed under behind its reverse proxy.
            '';
          };

          AllowedHosts = mkOption {
            type = types.str;
            default = "*";
            description = "Valid host names clients may use to connect.";
          };

          # TODO: rebind this as Url -> Urls idk why it's plural in robust.cdn...
          Urls = mkOption {
            type = types.str;
            default = "http://localhost:${toString cfg.port}/";
            description = ''
              URL and port for Robust.CDN to bind to. Robust.CDN should be served by
              a reverse proxy (nginx, etc), so this is localhost by default.
            '';
          };
        };
      };
      default = { };
      description = ''
        App settings, serialized to JSON. `$VAR` placeholders are supported for secrets,
        and will be expanded at service start from [](#opt-services.robust-cdn.environmentFile).
      '';
    };

    configFile = mkOption {
      type = types.path;
      default = format.generate "appsettings.json" cfg.settings;
      defaultText = literalMD "Generated from [](#opt-services.robust-cdn.settings).";
      description = ''
        Path to the Robust.CDN config file. Defaults to a file generated
        from {option}`settings`. Override to supply a raw file directly.
        `$VAR` placeholders are expanded with envsubst at startup if
        {option}`environmentFile` is set.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Environment file (systemd `EnvironmentFile=`) whose KEY=VALUE
        pairs populate any `$VAR` placeholders in the {option}`configFile`
        at startup.

        Use this to inject secrets from any secret manager:

        - agenix: `environmentFile = config.age.secrets.robust-cdn.path;`
        - sops-nix: `config.sops.secrets.robust-cdn.path`
        - root-owned file: /var/lib/some-imperative-secrets.env
        - etc...

        The file will not be copied into the Nix store.
      '';
      example = lib.literalExpression "config.age.secrets.robust-cdn.path";
    };
  };

  config = mkIf cfg.enable {
    users.users.robust-cdn = {
      isSystemUser = true;
      group = "robust-cdn";
      home = dataDir;
      description = "Robust.CDN service user";
    };
    users.groups.robust-cdn = { };

    systemd.services.robust-cdn = {
      description = "Space Station 14 Robust.CDN server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        User = "robust-cdn";
        Group = "robust-cdn";
        WorkingDirectory = dataDir;
        StateDirectory = "robust-cdn";
        UMask = "0077";

        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
        ExecStartPre =
          let
            command =
              if cfg.environmentFile != null then
                "${pkgs.envsubst}/bin/envsubst -i ${cfg.configFile} -o ${dataDir}/appsettings.json"
              else
                "ln -sf ${cfg.configFile} ${dataDir}/appsettings.json";
          in
          pkgs.writeShellScript "robust-cdn-prestart" ''
            ${command}
            mkdir -p ${dataDir}/builds
          '';

        ExecStart = "${cfg.package}/bin/Robust.Cdn";
        Restart = "on-failure";
        RestartSec = "5s";

        LogRateLimitIntervalSec = "10s";
        LogRateLimitBurst = "2000";

        StandardOutput = "journal";
        StandardError = "journal";

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
