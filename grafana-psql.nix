{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = "grafanareader";
  db = "ss14_main";
  # must contain GRAFANA_READER_PASSWORD="whatever"
  secrets_file = "/var/lib/secrets/psql.env";
  allowedCidrs = [
    "0.0.0.0/0"
  ];
  tables = [
    "play_time"
    "player"
    "player_round"
    "preference"
    "profile"
    "profile_loadout"
    "profile_loadout_group"
    "profile_role_loadout"
    "record_character"
    "record_edit"
    "role_whitelists"
    "round"
    "trait"
  ];

  psql = "${config.services.postgresql.package}/bin/psql";
  grantSQL = pkgs.writeText "${username}-grants.sql" ''
    \set ON_ERROR_STOP on
    \getenv pass GRAFANA_READER_PASSWORD

    BEGIN;

    GRANT CONNECT ON DATABASE "${db}" TO "${username}";
    GRANT USAGE ON SCHEMA public TO "${username}";

    REVOKE ALL ON ALL TABLES IN SCHEMA public FROM "${username}";

    GRANT SELECT ON TABLE
      ${lib.concatMapStringsSep ",\n  " (t: "public.\"${t}\"") tables}
    TO "${username}";

    ALTER ROLE "${username}" WITH PASSWORD :'pass';

    COMMIT;
  '';
in
{
  networking.firewall.allowedTCPPorts = [ 5432 ];

  services.postgresql = {
    enableTCPIP = true;

    ensureUsers = [
      { name = username; }
    ];

    authentication = lib.mkAfter (
      lib.concatMapStringsSep "\n" (cidr: "host ${db} ${username} ${cidr} scram-sha-256") allowedCidrs
    );
  };

  systemd.services."postgresql-grants-${username}" = {
    wantedBy = [ "multi-user.target" ];
    after = [ "postgresql-setup.service" ];
    requires = [ "postgresql-setup.service" ];

    enableStrictShellChecks = true;

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      EnvironmentFile = secrets_file;
      RemainAfterExit = true;
    };

    script = ''
      set -euo pipefail
      : "''${GRAFANA_READER_PASSWORD:?is not set in ${secrets_file}}"
      ${psql} --no-psqlrc -d ${db} -f ${grantSQL}
    '';
  };
}
