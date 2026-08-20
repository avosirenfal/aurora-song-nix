{
  pkgs,
  config,
  lib,
  ...
}:
let
  format = pkgs.formats.toml { };
in
{
  net = mkOption {
    description = "Network configuration.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        tickrate = mkOption {
          type = types.ints.positive;
          default = 30;
          description = "Server tickrate.";
        };
        port = mkOption {
          type = types.port;
          default = 1212;
          description = "UDP port used for main game netcode.";
        };
      };
    };
  };

  status = mkOption {
    description = "HTTP status API and launcher configuration.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        bind = mkOption {
          type = types.str;
          default = "*:1212";
          example = "127.0.0.1:3000";
          description = "Address and port to bind the HTTP status API to.";
        };
        connectaddress = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "udp://server.spacestation14.io:1212";
          description = "UDP address the main netcode should connect to (useful behind reverse proxies).";
        };
        privacy_policy_link = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Link to a HTTP(S) URL where your privacy policy is hosted.";
        };
        privacy_policy_identifier = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "A unique value that identifies a specific server group's privacy policy.";
        };
        privacy_policy_version = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "2024-11-30";
          description = "A unique value identifying the version of your privacy policy.";
        };
      };
    };
  };

  game = mkOption {
    description = "General game server settings.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        hostname = mkOption {
          type = types.str;
          default = "Space Station 14 Server";
          description = "Changes the name of the server as it appears in the lobby and launcher.";
        };
        lobbyenabled = mkOption {
          type = types.bool;
          default = false;
          description = "Enables the lobby instead of straight up throwing clients into a game.";
        };
      };
    };
  };

  auth = mkOption {
    description = "Authentication configuration.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        mode = mkOption {
          # TODO: replace this with something better
          type = types.enum [
            0
            1
            2
          ];
          default = 1;
          description = "0 (optional), 1 (required), 2 (disabled). Enforces authentication for clients.";
        };
        server = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "https://auth.fallback.spacestation14.com/";
          description = "Fallback authentication server if the main auth server is blocked.";
        };
      };
    };
  };

  build = mkOption {
    description = "Client download and codebase configuration.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        fork_id = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Identifier of your codebase. Used by launcher to manage installations.";
        };
        version = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Version string of the current build running on the server.";
        };
        engine_version = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Version of the engine to download.";
        };
        download_url = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Download locations of the entire client build in a zip, as a HTTP/HTTPS URL.";
        };
        hash = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "SHA256 hash of client zip files specified in download_url.";
        };
      };
    };
  };

  hub = mkOption {
    description = "Public hub advertising settings.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        advertise = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to advertise this server on the public hub list.";
        };
        server_url = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Change the server URL advertised on the master server list (e.g., for ss14s://).";
        };
        tags = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Comma separated list of tags.";
        };
        hub_urls = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "https://hub.fallback.spacestation14.com/";
          description = "Fallback hub URL if the primary is blocked.";
        };
      };
    };
  };

  database = mkOption {
    description = "Database configuration for saving player slots and preferences.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        engine = mkOption {
          type = types.enum [
            "sqlite"
            "postgres"
          ];
          default = "sqlite";
          description = "Database engine to use.";
        };
        sqlite_dbpath = mkOption {
          type = types.str;
          default = "preferences.db";
          description = "Path to the SQLite database, relative to the server data directory.";
        };
        pg_host = mkOption {
          type = types.str;
          default = "localhost";
          description = "PostgreSQL host.";
        };
        pg_port = mkOption {
          type = types.port;
          default = 5432;
          description = "PostgreSQL port.";
        };
        pg_database = mkOption {
          type = types.str;
          default = "ss14";
          description = "PostgreSQL database name.";
        };
        pg_username = mkOption {
          type = types.str;
          default = "";
          description = "PostgreSQL username.";
        };
        pg_password = mkOption {
          type = types.str;
          default = "";
          description = "PostgreSQL password.";
        };
      };
    };
  };

  admin = mkOption {
    description = "Admin configuration.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        api_token = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "API token for internal admin authentication.";
        };
        see_own_notes = mkOption {
          type = types.bool;
          default = true;
          description = "Whether admins can view notes placed on their own accounts.";
        };
      };
    };
  };

  console = mkOption {
    description = "Console permissions and host access.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        loginlocal = mkOption {
          type = types.bool;
          default = true;
          description = "Automatically elevate local connections (127.0.0.1 or ::1) to full admin privileges.";
        };
        login_host_user = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Automatically grant host permissions to this username upon connection.";
        };
      };
    };
  };

  discord = mkOption {
    description = "Discord webhook integrations.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        ahelp_webhook = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Webhook to send adminhelp messages to.";
        };
        round_update_webhook = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Webhook to send round status messages to.";
        };
      };
    };
  };

  loki = mkOption {
    description = "Loki structured logging configuration.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        enabled = mkOption {
          type = types.bool;
          default = false;
          description = "Enable pushing logs directly to a Loki server.";
        };
        address = mkOption {
          type = types.str;
          default = "http://localhost:3100";
          description = "HTTP address of the Loki server.";
        };
        name = mkOption {
          type = types.str;
          default = "ss14_server";
          description = "Name of this server, included in all log messages.";
        };
        username = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Username for HTTP Basic authentication with Loki.";
        };
        password = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Password for HTTP Basic authentication with Loki.";
        };
      };
    };
  };

  metrics = mkOption {
    description = "Prometheus metrics configuration.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        enabled = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Prometheus metrics scraping endpoint.";
        };
        host = mkOption {
          type = types.str;
          default = "localhost";
          description = "Address to bind the metrics server to. Use '*' for all local interfaces.";
        };
        port = mkOption {
          type = types.port;
          default = 44880;
          description = "Port to bind the metrics server to.";
        };
      };
    };
  };

  config = mkOption {
    description = "Preset overrides.";
    default = { };
    type = types.submodule {
      freeformType = format.type;
      options = {
        presets = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "_AS/aurora";
          description = "Server configuration presets to apply.";
        };
      };
    };
  };
}
