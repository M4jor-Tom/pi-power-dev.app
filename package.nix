{ lib
, writeShellApplication
, pi-coding-agent
, git
, gh
, glab
, nodejs
, bun
, ripgrep
, fd
, jq
, yq-go
, uv
, python3
, rtk
, graphify
, markitdown
, pandoc
, poppler-utils
, yt-dlp
  # Which profile this wrapper runs. Task 10 reuses this file with the
  # pi-game-dev values.
, profileName ? "pi-power-dev"
, configRepo ? "https://github.com/M4jor-Tom/pi-power-dev.git"
, dirEnvVar ? "PI_POWER_DEV_DIR"
}:

writeShellApplication {
  name = profileName;

  runtimeInputs = [
    pi-coding-agent
    git
    gh
    glab
    nodejs
    bun
    ripgrep
    fd
    jq
    yq-go
    uv
    python3
    rtk
    graphify
    markitdown
    pandoc
    poppler-utils
    yt-dlp
  ];

  # The config repo is a git working tree, never a store symlink: pi merges
  # its own fields back into settings.json under a lock, so that file has to
  # stay writable.
  text = ''
    DIR="''${${dirEnvVar}:-$HOME/.${profileName}}"

    if [ ! -e "$DIR" ]; then
      echo "${profileName}: cloning ${configRepo} -> $DIR" >&2
      git clone "${configRepo}" "$DIR"
    elif [ -d "$DIR/.git" ] && [ -z "$(git -C "$DIR" status --porcelain)" ]; then
      # Clean tree only. A dirty tree keeps its local edits, always.
      git -C "$DIR" pull --ff-only --quiet \
        || echo "${profileName}: pull failed, using the local checkout" >&2
    fi

    export PI_CODING_AGENT_DIR="$DIR"
    exec pi "$@"
  '';

  meta = {
    description = "pi coding agent running the ${profileName} profile";
    homepage = "https://github.com/M4jor-Tom/${profileName}.app";
    mainProgram = profileName;
    platforms = lib.platforms.unix;
  };
}
