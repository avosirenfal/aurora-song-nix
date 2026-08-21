{
  game = {
    hostname = "[18+][MRP] Aurora's Song";
    soft_max_players = 100;
  };

  auth = {
    mode = 1;
    server = "https://auth.playss14.com/";
  };

  status = {
    enabled = true;
    connectaddress = "udp://test.aurorasong.gay:1212";
    # connectaddress = "udp://167.114.208.152:1212";
  };

  hub = {
    server_url = "ss14s://test.aurorasong.gay/game";
    # server_url = "ss14s://167.114.208.152/game";
    hub_urls = "https://hub.playss14.com/";
    advertise = false;
    tags = "";
  };

  net = {
    tickrate = 30;
    port = 1212;
    max_connections = 256;
    log_late_msg = false;
  };

  whitelist = {
    enabled = true;
  };

  admin = {
    api_token = "$ADMIN_API_TOKEN";
    see_own_notes = true;
  };

  ic = {
    restricted_names = false;
  };

  shuttle = {
    auto_call_time = 2880;
  };

  atmos = {
    delta_pressure_damage = false;
    space_wind = false;
  };

  npc = {
    player_pause_distance = 40;
  };

  nf14 = {
    respawn = {
      time = 20;
    };
    gc = {
      idle_count = 1;
      period = 300;
    };
  };

  infolinks = {
    discord = "https://discord.gg/aurorasong";
    github = "https://github.com/AuroraSong14/Aurora-Song-14";
    wiki = "https://wiki.aurorasong.gay/index.php?title=Main_Page";
    bug_report = "https://github.com/AuroraSong14/Aurora-Song-14/issues";
  };
}
