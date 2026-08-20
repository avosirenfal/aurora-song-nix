{ config, pkgs, ... }:
let
  # you have to create this file manually on the host!!!
  # it should have `AURORASONG_UPDATE_TOKEN="something"` in it
  secretsFile = "/var/lib/secrets/robust-cdn.env";
in
{
  imports = [
    ./ss14/nixos/robust-cdn.nix
    ./ss14/nixos/watchdog.nix
    ./ss14/nixos/servers.nix
  ];

  services.ss14-watchdog.environmentFile = secretsFile;
  services.ss14-watchdog.settings.BaseUrl = "https://aurorasong.gay/watchdog";
  services.ss14-watchdog.instances.main.ApiToken = "$AURORASONG_INSTANCE_TOKEN";
  services.ss14-watchdog.settings.Notification.DiscordWebhook = "$WATCHDOG_WEBHOOK";

  services.robust-cdn = {
    enable = true;

    environmentFile = secretsFile;

    settings = {
      BaseUrl = "https://cdn.aurorasong.gay/";
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

  services.ss14-servers = {
    enable = true;

    instances.main = {
      name = "aurorasong";
      bindIp = "0.0.0.0";
      port = 1212;

      postgres = true;
      prometheus = true;

      manifestUrl = "https://cdn.aurorasong.gay/fork/aurorasong/manifest";

      Settings = {
        game.hostname = "Aurora Song";
      };
    };
  };

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    virtualHosts."cdn.aurorasong.gay" = {
      #enableACME = true;
      #forceSSL = true;

      locations."/" = {
        proxyPass = "http://localhost:${toString config.services.robust-cdn.port}";
        proxyWebsockets = true; # dunno if robust-cdn uses websockets
      };
    };
  };

  #security.acme = {
  #  acceptTerms = true;
  #  defaults.email = "admin@aurorasong.gay";
  #};
}
