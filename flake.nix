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
      in
      {
        packages.${system} = {
          default = pkgs.pi-power-dev;
          pi-power-dev = pkgs.pi-power-dev;
        };

        apps.${system} = {
          default = {
            type = "app";
            program = "${pkgs.pi-power-dev}/bin/pi-power-dev";
          };
          pi-power-dev = {
            type = "app";
            program = "${pkgs.pi-power-dev}/bin/pi-power-dev";
          };
        };

        devShells.${system}.default = pkgs.mkShell {
          buildInputs = with pkgs; [ nixpkgs-fmt ];
        };
      }) // {
      overlays.default = overlay;
    };
}
