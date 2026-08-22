{ config, pkgs, ... }:
let
  # you have to create this file manually on the host!!!
  # it should have the following values:
  # AURORASONG_UPDATE_TOKEN="something"
  # AURORASONG_INSTANCE_TOKEN="something"
  # ADMIN_API_TOKEN="something"
  # WATCHDOG_WEBHOOK="something"
  # AHELP_WEBHOOK="something"
  # ROUND_UPDATE_WEBHOOK="something"
  secretsFile = "/var/lib/secrets/ss14.env";

  # TODO: haven't figured out a good way to wrap serilog stuff for nix yet
  serilog = {
    Using = [
      "Serilog.Sinks.Console"
      "Serilog.Sinks.Loki"
    ];
    MinimumLevel = {
      Default = "Information";
      Override = {
        SS14 = "Information";
        Microsoft = "Warning";
        "Microsoft.Hosting.Lifetime" = "Information";
        "Microsoft.AspNetCore" = "Warning";
      };
    };
    WriteTo = [
      {
        Name = "Console";
        Args = {
          OutputTemplate = "[{Timestamp:HH:mm:ss} {Level:u3} {SourceContext}] {Message:lj}{NewLine}{Exception}";
        };
      }
    ];
    Enrich = [ "FromLogContext" ];
  };
in
{
  imports = [
    ./ss14/nixos/robust-cdn.nix
    ./ss14/nixos/watchdog.nix
    ./ss14/nixos/servers.nix
  ];

  services.ss14-watchdog.environmentFile = secretsFile;
  services.ss14-watchdog.instances.main.ApiToken = "$AURORASONG_INSTANCE_TOKEN";
  services.ss14-watchdog.settings.Process.PersistServers = true;
  services.ss14-watchdog.settings.Serilog = serilog;

  services.robust-cdn.settings.BaseUrl = "https://cdn.aurorasong.gay/";
  services.ss14-servers.instances.main.manifestUrl =
    "https://cdn.aurorasong.gay/fork/aurorasong/manifest";

  # bind to external ip instead of aurorasong.gay
  /*
    services.robust-cdn.settings.Urls = "http://167.114.208.152:27690";
    services.robust-cdn.settings.BaseUrl = "http://167.114.208.152:27690/";
    services.ss14-servers.instances.main.manifestUrl =
      "http://167.114.208.152:27690/fork/aurorasong/manifest";
  */

  services.ss14-watchdog.settings.Notification.DiscordWebhook = "$WATCHDOG_WEBHOOK";
  services.ss14-servers.instances.main.Settings = (import ./ss14-aurora.nix) // {
    discord = {
      ahelp_webhook = "$AHELP_WEBHOOK";
      round_update_webhook = "$ROUND_UPDATE_WEBHOOK";
    };
  };

  # apparently good for performance
  # https://docs.spacestation14.com/en/general-development/setup/server-hosting-tutorial.html
  services.ss14-watchdog.instances.main.EnvironmentVariables = {
    DOTNET_gcServer = "1";
    DOTNET_TieredPGO = "1";
    DOTNET_TC_QuickJitForLoops = "1";
    DOTNET_ReadyToRun = "0";
    ROBUST_NUMERICS_AVX = "true";
  };

  services.ss14-servers = {
    enable = true;

    instances.main = {
      name = "aurorasong";

      postgres = true;
      prometheus = true;
      loki = true;
    };
  };

  services.robust-cdn = {
    enable = true;

    environmentFile = secretsFile;

    settings = {
      PathBase = "/";

      Manifest.Forks.aurorasong = {
        UpdateToken = "$AURORASONG_UPDATE_TOKEN";
        DisplayName = "Aurorasong";
        BuildsPageLink = "https://www.youtube.com/watch?v=xvFZjo5PgG0";
        BuildsPageLinkText = "Aurorasong";
        PruneBuildsDays = 90;

        NotifyWatchdogs = [
          {
            WatchdogUrl = config.services.ss14-watchdog.settings.Urls;
            Instance = "main";
            ApiToken = config.services.ss14-watchdog.instances.main.ApiToken;
          }
        ];
      };

      Cdn = {
        StreamCompressLevel = 5;
      };
    };
  };

  powerManagement.cpuFreqGovernor = "performance";
  boot.kernel.sysctl = {
    "net.core.wmem_max" = 8388608;
    "net.core.rmem_max" = 8388608;
    "net.core.wmem_default" = 262144;
    "net.core.rmem_default" = 262144;
    "net.core.netdev_max_backlog" = 5000;
  };

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    virtualHosts."cdn.aurorasong.gay" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://localhost:${toString config.services.robust-cdn.port}";
        proxyWebsockets = true; # dunno if robust-cdn uses websockets
      };

      locations."~ ^/fork/.*/publish/file" = {
        proxyPass = "http://localhost:${toString config.services.robust-cdn.port}";

        extraConfig = ''
          client_max_body_size 5G;
        '';
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@aurorasong.gay";
  };

  services.postgresql = {
    enable = true;

    extensions =
      ps: with ps; [
        pg_repack
      ];
  };
}
