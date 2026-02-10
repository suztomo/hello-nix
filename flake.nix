{
  description = "Nix build for python-multi container image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        packages.default = pkgs.callPackage ./python-multi.nix {};
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nix-build
            skopeo # for inspecting images
          ];
        };
      }
    );
}
