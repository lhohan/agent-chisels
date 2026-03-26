#!/usr/bin/env fish

function __sandbox_agent_script
    set -l here (path dirname (status --current-filename))
    echo "$here/sandbox-agent.sh"
end

function safe --description "Run command through sandbox-agent.sh"
    set -l runner (__sandbox_agent_script)
    if not test -x "$runner"
        echo "safe: sandbox-agent runner not executable: $runner" >&2
        return 127
    end

    "$runner" $argv
end

function ocy --description "Run opencode through sandbox-agent with permissive inner mode"
    # Permissions:
    # - allow all tools, `external_directory`: seems to be necessary in addition to not have 'Ask' when going outside working dir
    # - git: deny: personal tooling preference:  because I use use jj)
    # - doom_loop: ask: LLM specific which cannot be controlled by sandbox
    set -lx OPENCODE_PERMISSION '{"*":"allow", "doom_loop": "ask", "external_directory": "allow" ,"git *": "deny"}'
    safe opencode $argv
end

function cxy --description "Run codex through sandbox-agent with --yolo"
    safe codex --yolo $argv
end
