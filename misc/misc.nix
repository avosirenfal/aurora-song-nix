{
  pkgs,
  lib,
  config,
  ...
}:
{
  # allow root to psql directly if postgres is enabled
  services.postgresql = {
    ensureUsers = [
      {
        name = "root";
        ensureClauses = {
          superuser = true;
          login = true;
        };
      }
    ];

    /*
      authentication = ''
        # type database  user  auth-method
        local  all       all   peer map=rootmap
      '';

      identMap = ''
        # map-name  system-username  database-username
        rootmap     root             all
      '';
    */
  };

  programs.bash.interactiveShellInit = lib.mkIf config.services.postgresql.enable ''
    if [ "$USER" = "root" ]; then
      export PGDATABASE="postgres";
    fi
  '';
}
