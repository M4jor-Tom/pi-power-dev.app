{
  description = "pi coding agent, pre-loaded with the pi-power-dev profile";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    { self
    , nixpkgs
    , systems
    }:
    let
      inherit (nixpkgs) lib;
      eachSystem = f: lib.foldl' lib.recursiveUpdate { } (map f (import systems));

      overlay = final: prev: {
        pi-power-dev = final.callPackage ./package.nix { };
      };
    in
    eachSystem
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
        ollama = lib.getExe pkgs.ollama;
        pi = lib.getExe pkgs.pi-power-dev;
        managed = "${lib.getExe pkgs.python3} ${./with-ollama.py} ${ollama}";
        app = name: description: text: {
          type = "app";
          program = lib.getExe (pkgs.writeShellApplication { inherit name text; });
          meta = { inherit description; };
        };
      in
      {
        packages.${system} = {
          default = pkgs.pi-power-dev;
          pi-power-dev = pkgs.pi-power-dev;
        };

        apps.${system} = {
          ollama = app "ollama" "Ollama terminal menu or CLI with a session-local server" ''
            if [[ ''${1:-} == serve ]]; then
              echo 'No serve step needed: use the menu, list, or pull MODEL.' >&2
              exit 2
            fi
            exec ${managed} ${ollama} "$@"
          '';
          pi-with-ollama = app "pi-with-ollama" "Pi with its own temporary Ollama server" ''
            case "''${1:-}" in
              auth|config|install|list|mcp|remove|uninstall|update) exec ${pi} "$@" ;;
            esac
            exec ${managed} ${pi} --extension ${./ollama.js} "$@"
          '';
          default = {
            type = "app";
            program = "${pkgs.pi-power-dev}/bin/pi-power-dev";
            meta.description = "pi coding agent running the pi-power-dev profile";
          };
          pi-power-dev = {
            type = "app";
            program = "${pkgs.pi-power-dev}/bin/pi-power-dev";
            meta.description = "pi coding agent running the pi-power-dev profile";
          };
        };

        checks.${system}.ollama = pkgs.runCommand "test-pi-ollama" {
          __darwinAllowLocalNetworking = true;
        } ''
          cp ${./ollama.js} ollama.js
          cp ${./test-ollama.mjs} test-ollama.mjs
          ${lib.getExe pkgs.nodejs} --test test-ollama.mjs
          cp ${./with-ollama.py} with-ollama.py
          ${lib.getExe pkgs.python3} ${./test-lifecycle.py} ${ollama}
          touch "$out"
        '';

        devShells.${system}.default = pkgs.mkShell {
          buildInputs = with pkgs; [ nixpkgs-fmt ];
        };
      }) // {
      overlays.default = overlay;
    };
}
