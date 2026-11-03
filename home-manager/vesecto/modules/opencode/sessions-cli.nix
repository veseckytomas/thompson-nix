#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{pkgs, ...}:
# Twin of the session_list_all agent tool in plugins/session-list-all/plugin.js - columns, filters and SQL must change in both.
pkgs.writeShellApplication {
  name = "opencode-session-list-all";
  runtimeInputs = [pkgs.sqlite pkgs.coreutils pkgs.util-linux];
  text = ''
    db="''${OPENCODE_DB:-''${XDG_DATA_HOME:-$HOME/.local/share}/opencode/opencode.db}"
    limit=30
    search=""
    dir=""
    include_all=false
    json=false

    usage() {
      cat <<'EOF'
    Usage: opencode session list-all [options]

    Options:
      -n, --limit N  Maximum sessions to list (default: 30, max: 200)
      --search TEXT  Filter by title (case-insensitive) or directory (case-sensitive)
      --dir TEXT     Filter by directory (case-sensitive)
      --all          Include archived sessions and subsessions
      --json         Output a JSON array
      -h, --help     Show this help
    EOF
    }

    sqlesc() {
      printf "%s" "$1" | sed "s/'/'''/g"
    }

    while [ $# -gt 0 ]; do
      case "$1" in
        -n | --limit)
          if [ $# -lt 2 ]; then
            printf 'opencode-session-list-all: %s requires a value\n' "$1" >&2
            usage >&2
            exit 2
          fi
          limit="$2"
          shift 2
          ;;
        --search)
          if [ $# -lt 2 ]; then
            printf 'opencode-session-list-all: %s requires a value\n' "$1" >&2
            usage >&2
            exit 2
          fi
          search="$2"
          shift 2
          ;;
        --dir)
          if [ $# -lt 2 ]; then
            printf 'opencode-session-list-all: %s requires a value\n' "$1" >&2
            usage >&2
            exit 2
          fi
          dir="$2"
          shift 2
          ;;
        --all)
          include_all=true
          shift
          ;;
        --json)
          json=true
          shift
          ;;
        -h | --help)
          usage
          exit 0
          ;;
        *)
          printf 'opencode-session-list-all: unknown option: %s\n' "$1" >&2
          usage >&2
          exit 2
          ;;
      esac
    done

    case "$limit" in
      "" | *[!0-9]*)
        printf 'opencode-session-list-all: invalid limit: %s\n' "$limit" >&2
        usage >&2
        exit 2
        ;;
    esac
    if [ "$limit" -gt 200 ]; then
      limit=200
    fi

    if [ ! -f "$db" ]; then
      printf 'opencode-session-list-all: no database at %s\n' "$db" >&2
      exit 0
    fi

    where="1 = 1"
    if [ "$include_all" = false ]; then
      where="$where AND s.time_archived IS NULL AND s.parent_id IS NULL"
    fi
    # opencode scopes sessions by project, so a path is resolved to its project(s) and every session there matches - sibling worktrees share one project and would otherwise be invisible.
    scope_sql() {
      printf "s.project_id IN (SELECT s2.project_id FROM \"session\" s2 LEFT JOIN project p2 ON p2.id = s2.project_id WHERE instr(s2.directory, '%s') > 0 OR (p2.worktree IS NOT NULL AND instr(p2.worktree, '%s') > 0))" "$1" "$1"
    }

    if [ -n "$dir" ]; then
      e=$(sqlesc "$dir")
      where="$where AND (instr(s.directory, '$e') > 0 OR (p.worktree IS NOT NULL AND instr(p.worktree, '$e') > 0) OR $(scope_sql "$e"))"
    fi
    if [ -n "$search" ]; then
      e=$(sqlesc "$search")
      where="$where AND (instr(lower(s.title), lower('$e')) > 0 OR instr(s.directory, '$e') > 0 OR (p.worktree IS NOT NULL AND instr(p.worktree, '$e') > 0) OR $(scope_sql "$e"))"
    fi

    from="FROM \"session\" s LEFT JOIN project p ON p.id = s.project_id"
    order_limit="ORDER BY s.time_updated DESC LIMIT $limit"

    if [ "$json" = true ]; then
      sqlite3 -readonly "file:$db?mode=ro" "
        SELECT json_group_array(json_object(
          'id', q.id,
          'title', q.title,
          'directory', q.directory,
          'updated', q.time_updated
        ))
        FROM (
          SELECT s.id, s.title, s.directory, s.time_updated
          $from
          WHERE $where
          $order_limit
        ) q;
      "
      exit 0
    fi

    rows=$(sqlite3 -readonly -separator $'\t' "file:$db?mode=ro" "
      SELECT
        s.id,
        substr(replace(replace(s.title, char(9), ' '), char(10), ' '), 1, 60),
        s.directory,
        strftime('%Y-%m-%d %H:%M', s.time_updated / 1000, 'unixepoch')
      $from
      WHERE $where
      $order_limit;
    ")

    if [ -z "$rows" ]; then
      printf 'No sessions found.\n'
      exit 0
    fi

    total=$(sqlite3 -readonly "file:$db?mode=ro" "SELECT COUNT(*) $from WHERE $where;")
    shown=$(printf '%s\n' "$rows" | wc -l)

    {
      printf 'Session ID\tTitle\tDirectory\tUpdated\n'
      printf '%s\n' "$rows"
    } | column -t -s $'\t'

    if [ "$total" -gt "$shown" ]; then
      printf '\nShowing %s of %s matching sessions; use --limit (max 200) to see more.\n' "$shown" "$total"
    fi
  '';
}
