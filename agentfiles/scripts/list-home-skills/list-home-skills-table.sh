#!/usr/bin/env bash

set -euo pipefail

if [[ -t 1 ]]; then
  COLOR_RESET=$'\033[0m'
  COLOR_HEADER=$'\033[1;37m'
  COLOR_LOCAL=$'\033[0;37m'
  COLOR_PRIVATE=$'\033[0;36m'
  COLOR_PUBLIC=$'\033[0;32m'
  COLOR_BROKEN=$'\033[1;31m'
  COLOR_META=$'\033[0;90m'
else
  COLOR_RESET=""
  COLOR_HEADER=""
  COLOR_LOCAL=""
  COLOR_PRIVATE=""
  COLOR_PUBLIC=""
  COLOR_BROKEN=""
  COLOR_META=""
fi

SKILL_LOCATIONS=(
  "codex:$HOME/.codex/skills"
  # "claude:$HOME/.claude/skills"
  "opencode:$HOME/.config/opencode/skills"
  "vibe:$HOME/.vibe/skills"
)

rows=()
PROVENANCE_LABEL="local"
has_local=0
has_private=0
has_public=0
has_external=0
has_broken=0

classify_source() {
  local resolved_path="$1"

  case "$resolved_path" in
    *"/dotfiles/"*)
      printf 'private'
      ;;
    *"/agent-chisels/"*)
      printf 'public'
      ;;
    *)
      printf 'external'
      ;;
  esac
}

add_origin_flag() {
  local origin="$1"
  case "$origin" in
    local) has_local=1 ;;
    private) has_private=1 ;;
    public) has_public=1 ;;
    external) has_external=1 ;;
    broken-link) has_broken=1 ;;
  esac
}

inspect_skill_provenance() {
  local skill_path="$1"
  local scan_root=""
  local resolved_skill_path=""
  local skill_path_resolves_elsewhere=0
  local node=""
  local origin=""

  has_local=0
  has_private=0
  has_public=0
  has_external=0
  has_broken=0

  if resolved_skill_path="$(realpath "$skill_path" 2>/dev/null)"; then
    scan_root="$resolved_skill_path"
    if [[ "$resolved_skill_path" != "$skill_path" ]]; then
      skill_path_resolves_elsewhere=1
      add_origin_flag "$(classify_source "$resolved_skill_path")"
    fi
  else
    add_origin_flag "broken-link"
    PROVENANCE_LABEL='broken-link'
    return
  fi

  if [[ -d "$scan_root" ]]; then
    while IFS= read -r -d '' node; do
      if [[ -L "$node" ]]; then
        if origin="$(realpath "$node" 2>/dev/null)"; then
          add_origin_flag "$(classify_source "$origin")"
        else
          add_origin_flag "broken-link"
        fi
      else
        # Non-symlink directories are just containers; only real files imply local content.
        if [[ -f "$node" ]]; then
          if (( skill_path_resolves_elsewhere == 1 )); then
            add_origin_flag "$(classify_source "$node")"
          elif [[ "$skill_path" == "$scan_root" ]]; then
            add_origin_flag "local"
          else
            add_origin_flag "$(classify_source "$node")"
          fi
        fi
      fi
    done < <(find "$scan_root" -mindepth 1 -print0)
  fi

  if (( has_broken == 1 )); then
    PROVENANCE_LABEL='broken-link'
    return
  fi

  if (( has_public == 1 || has_external == 1 )); then
    PROVENANCE_LABEL='public'
    return
  fi

  if (( has_private == 1 )); then
    PROVENANCE_LABEL='private'
    return
  fi

  if (( has_local == 1 )); then
    PROVENANCE_LABEL='local'
    return
  fi

  if [[ "$skill_path" == "$scan_root" ]]; then
    PROVENANCE_LABEL='local'
    return
  fi

  PROVENANCE_LABEL='public'
}

collect_rows_for_location() {
  local agent="$1"
  local skills_dir="$2"
  local rows_before=${#rows[@]}
  local skill_dirs=()
  local skill_marker=""
  local skill_dir=""

  if [[ ! -d "$skills_dir" ]]; then
    rows+=("$agent|*missing*|missing-dir|$skills_dir")
    return
  fi

  # A directory is a skill when it contains SKILL.md/skill.md (regular file or symlink).
  while IFS= read -r -d '' skill_marker; do
    skill_dir="$(dirname "$skill_marker")"
    skill_dirs+=("$skill_dir")
  done < <(find -L "$skills_dir" \( -type f -o -type l \) -iname 'skill.md' -print0)

  if [[ ${#skill_dirs[@]} -eq 0 ]]; then
    rows+=("$agent|*empty*|empty-dir|$skills_dir")
    return
  fi

  mapfile -t skill_dirs < <(printf '%s\n' "${skill_dirs[@]}" | sort -u)

  local entry
  for entry in "${skill_dirs[@]}"; do
    local skill_name
    local link_to
    local source

    skill_name="$(basename "$entry")"

    if link_to="$(realpath "$entry" 2>/dev/null)"; then
      inspect_skill_provenance "$entry"
      source="$PROVENANCE_LABEL"
    else
      link_to="$entry"
      source="broken-link"
    fi

    rows+=("$agent|$skill_name|$source|$link_to")
  done

  if [[ ${#rows[@]} -eq rows_before ]]; then
    rows+=("$agent|*empty*|empty-dir|$skills_dir")
  fi
}

for spec in "${SKILL_LOCATIONS[@]}"; do
  agent="${spec%%:*}"
  skills_dir="${spec#*:}"
  collect_rows_for_location "$agent" "$skills_dir"
done

mapfile -t rows < <(printf '%s\n' "${rows[@]}" | sort)

name_w=5
agent_w=5
source_w=6
link_w=9

for row in "${rows[@]}"; do
  IFS='|' read -r agent skill source linked_to <<< "$row"
  display_linked_to="$linked_to"
  if [[ "$display_linked_to" == "$HOME" ]]; then
    display_linked_to="~"
  elif [[ "$display_linked_to" == "$HOME/"* ]]; then
    display_linked_to="~/${display_linked_to#"$HOME/"}"
  fi

  (( ${#agent} > agent_w )) && agent_w=${#agent}
  (( ${#skill} > name_w )) && name_w=${#skill}
  (( ${#source} > source_w )) && source_w=${#source}
  (( ${#display_linked_to} > link_w )) && link_w=${#display_linked_to}
done

printf '%b' "$COLOR_HEADER"
printf "%-${agent_w}s  %-${name_w}s  %-${source_w}s  %-${link_w}s\n" \
  "agent" "skill" "source" "linked_to"
printf "%-${agent_w}s  %-${name_w}s  %-${source_w}s  %-${link_w}s\n" \
  "$(printf '%*s' "$agent_w" '' | tr ' ' '-')" \
  "$(printf '%*s' "$name_w" '' | tr ' ' '-')" \
  "$(printf '%*s' "$source_w" '' | tr ' ' '-')" \
  "$(printf '%*s' "$link_w" '' | tr ' ' '-')"
printf '%b' "$COLOR_RESET"

for row in "${rows[@]}"; do
  IFS='|' read -r agent skill source linked_to <<< "$row"
  display_linked_to="$linked_to"
  if [[ "$display_linked_to" == "$HOME" ]]; then
    display_linked_to="~"
  elif [[ "$display_linked_to" == "$HOME/"* ]]; then
    display_linked_to="~/${display_linked_to#"$HOME/"}"
  fi
  row_color="$COLOR_RESET"
  case "$source" in
    local) row_color="$COLOR_LOCAL" ;;
    private) row_color="$COLOR_PRIVATE" ;;
    public) row_color="$COLOR_PUBLIC" ;;
    broken-link) row_color="$COLOR_BROKEN" ;;
    missing-dir|empty-dir) row_color="$COLOR_META" ;;
    *) row_color="$COLOR_RESET" ;;
  esac

  printf '%b' "$row_color"
  printf "%-${agent_w}s  %-${name_w}s  %-${source_w}s  %-${link_w}s\n" \
    "$agent" "$skill" "$source" "$display_linked_to"
  printf '%b' "$COLOR_RESET"
done
