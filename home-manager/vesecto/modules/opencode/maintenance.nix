#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  pkgs,
  config,
  ...
}: let
  dbPath = "${config.xdg.dataHome}/opencode/opencode-stable.db";
  # Rolling retention in days; 0 disables age-pruning (VACUUM still reclaims freelist).
  ageDays = 30;
  # Delete sessions whose stored parts exceed this many MB (the giants that slow session loads).
  sizeMb = 12;
  maint = pkgs.writeShellApplication {
    name = "opencode-db-maint";
    runtimeInputs = [pkgs.sqlite pkgs.coreutils pkgs.procps pkgs.systemd];
    text = ''
      db="''${OPENCODE_DB_PATH:-${dbPath}}"
      age_days="''${AGE_DAYS:-${toString ageDays}}"
      size_mb="''${SIZE_MB:-${toString sizeMb}}"

      # OPENCODE_DB_MAINT_NO_SERVICE=1 skips the client guard + server stop (used by the copy-test).
      if [ -z "''${OPENCODE_DB_MAINT_NO_SERVICE:-}" ]; then
        if pgrep -f '^opencode( (attach|run)( .*)?)?$' >/dev/null 2>&1; then
          echo "opencode-db-maint: interactive client active, skipping"
          exit 0
        fi
        systemctl --user stop opencode-server.service 2>/dev/null || true
        sleep 1
      fi

      if [ ! -f "$db" ]; then
        echo "opencode-db-maint: no database at $db"
        exit 0
      fi

      if [ "$(sqlite3 "$db" 'PRAGMA quick_check;')" != "ok" ]; then
        echo "opencode-db-maint: quick_check failed, aborting before destructive ops" >&2
        exit 1
      fi

      before=$(stat -c%s "$db")

      age_delete=""
      if [ "$age_days" -gt 0 ]; then
        age_delete="DELETE FROM session WHERE time_updated IS NOT NULL AND time_updated < (strftime('%s','now') - $age_days * 86400) * 1000;"
      fi

      sqlite3 "$db" "PRAGMA busy_timeout=30000;
      PRAGMA foreign_keys=ON;
      PRAGMA wal_checkpoint(TRUNCATE);
      $age_delete
      DELETE FROM session WHERE id IN (
        SELECT m.session_id FROM part p JOIN message m ON p.message_id = m.id
        GROUP BY m.session_id HAVING sum(length(CAST(p.data AS BLOB))) > $size_mb * 1048576
      );
      PRAGMA auto_vacuum=INCREMENTAL;
      VACUUM;
      ANALYZE;"

      if [ -n "$(sqlite3 "$db" 'PRAGMA foreign_key_check;')" ]; then
        echo "opencode-db-maint: foreign_key_check found orphans" >&2
        exit 1
      fi
      if [ "$(sqlite3 "$db" 'PRAGMA integrity_check;')" != "ok" ]; then
        echo "opencode-db-maint: integrity_check failed" >&2
        exit 1
      fi

      after=$(stat -c%s "$db")
      echo "opencode-db-maint: $db $before -> $after bytes (age_days=$age_days size_mb=$size_mb)"
    '';
  };
in {
  systemd.user.services.opencode-db-maint = {
    Unit.Description = "Compact and prune the opencode SQLite session store (offline)";
    Service = {
      Type = "oneshot";
      ExecStart = "${maint}/bin/opencode-db-maint";
    };
  };

  systemd.user.timers.opencode-db-maint = {
    Unit.Description = "Daily opencode session-database compaction";
    Timer = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
    Install.WantedBy = ["timers.target"];
  };
}
