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
  dbPath = "${config.xdg.dataHome}/opencode/opencode.db";
  # Rolling session retention in days.
  ageDays = 7;
  # Delete sessions whose stored parts exceed this many MB (the giants that slow session loads).
  sizeMb = 12;
  # Skip size-prune for sessions touched within this window (protects live sessions without process detection).
  activeHours = 1;
  maint = pkgs.writeShellApplication {
    name = "opencode-db-maint";
    runtimeInputs = [pkgs.sqlite pkgs.coreutils];
    text = ''
      db="''${OPENCODE_DB_PATH:-${dbPath}}"
      age_days="''${AGE_DAYS:-${toString ageDays}}"
      size_mb="''${SIZE_MB:-${toString sizeMb}}"
      active_hours="''${ACTIVE_HOURS:-${toString activeHours}}"

      if [ ! -f "$db" ]; then
        echo "opencode-db-maint: no database at $db"
        exit 0
      fi

      if [ "$(sqlite3 "$db" 'PRAGMA quick_check;')" != "ok" ]; then
        echo "opencode-db-maint: quick_check failed, aborting before destructive ops" >&2
        exit 1
      fi

      before=$(stat -c%s "$db")

      # No server stop: runs alongside a live opencode-server or with the unit absent.
      sqlite3 "$db" "PRAGMA busy_timeout=30000;
      PRAGMA foreign_keys=ON;
      -- never prune a (TODO)-titled session or anything below it in the subsession tree
      WITH RECURSIVE protected(id) AS (
        SELECT id FROM session WHERE instr(title, '(TODO)') > 0
        UNION
        SELECT s.id FROM session s JOIN protected pr ON s.parent_id = pr.id
      )
      DELETE FROM session WHERE time_updated IS NOT NULL AND time_updated < (strftime('%s','now') - $age_days * 86400) * 1000 AND id NOT IN (SELECT id FROM protected);
      WITH RECURSIVE protected(id) AS (
        SELECT id FROM session WHERE instr(title, '(TODO)') > 0
        UNION
        SELECT s.id FROM session s JOIN protected pr ON s.parent_id = pr.id
      )
      DELETE FROM session WHERE id IN (
        SELECT m.session_id FROM part p
        JOIN message m ON p.message_id = m.id
        JOIN session s ON s.id = m.session_id
        WHERE s.time_updated < (strftime('%s','now') - $active_hours * 3600) * 1000
        GROUP BY m.session_id HAVING sum(length(CAST(p.data AS BLOB))) > $size_mb * 1048576
      ) AND id NOT IN (SELECT id FROM protected);"

      # VACUUM needs exclusive access; fall back to a WAL checkpoint when a live server holds the lock.
      if ! sqlite3 "$db" "PRAGMA busy_timeout=30000; VACUUM;" 2>/dev/null; then
        sqlite3 "$db" "PRAGMA busy_timeout=30000; PRAGMA wal_checkpoint(TRUNCATE);" 2>/dev/null || true
        echo "opencode-db-maint: VACUUM skipped (db busy), wal_checkpoint attempted" >&2
      fi

      sqlite3 "$db" "PRAGMA busy_timeout=30000; ANALYZE;" 2>/dev/null || true

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
    Unit.Description = "Compact and prune the opencode SQLite session store (concurrent-safe)";
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
