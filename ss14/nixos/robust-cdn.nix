{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.robust-cdn;
  ss14-packages = import ../packages/default.nix { inherit pkgs; };
in
{
  options.services.robust-cdn = {
    enable = mkEnableOption "Space Station 14 Robust.CDN server";

    package = mkOption {
      type = types.package;
      default = ss14-packages.robust-cdn;
      description = "The Robust.CDN package to use.";
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = format.type;
        options = {
          port = mkOption {
            type = types.port;
            default = 27690;
            description = "Local port Robust.CDN listens on behind nginx.";
          };

          dataDir = mkOption {
            type = types.path;
            default = "/var/lib/robust-cdn";
            description = "Directory for builds, databases, and config.";
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
      home = cfg.dataDir;
      createHome = true;
      description = "Robust.CDN service user";
    };
    users.groups.robust-cdn = { };

    systemd.services.robust-cdn = {
      description = "Space Station 14 Robust.CDN server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "notify";
        User = "robust-cdn";
        Group = "robust-cdn";
        WorkingDirectory = cfg.dataDir;

        ExecStartPre = pkgs.writeShellScript "robust-cdn-prestart" ''
          ln -sf ${appSettings} ${cfg.dataDir}/appsettings.json
          mkdir -p ${cfg.dataDir}/{builds,manifest,database}
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
        ReadWritePaths = [ cfg.dataDir ];
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        LockPersonality = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
