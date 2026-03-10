{
  description = "podman-remote - Podman remote client";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      version = "5.8.0";

      releases = {
        x86_64-linux = {
          url = "podman-remote-static-linux_amd64.tar.gz";
          sha256 = "sha256-lfNIEm9wji8YyFNBo2MISQVdcqPSLT4QIUYzEndYhjc=";
          format = "tar";
          binPath = "bin/podman-remote-static-linux_amd64";
        };
        aarch64-linux = {
          url = "podman-remote-static-linux_arm64.tar.gz";
          sha256 = "sha256-ad3e00885b27034b34f508c21265d43dd62f3d11b69fa822390800bfc17fe3f7";
          format = "tar";
          binPath = "bin/podman-remote-static-linux_arm64";
        };
        x86_64-darwin = {
          url = "podman-remote-release-darwin_amd64.zip";
          sha256 = "sha256-a4d68a7be94d2c6f9c752731736ab0ec5145bc5b5ac5909d6b5bc36badd73f44";
          format = "zip";
          binPath = "podman-5.8.0/usr/bin/podman";
        };
        aarch64-darwin = {
          url = "podman-remote-release-darwin_arm64.zip";
          sha256 = "sha256-dfd1bb61afab0cffb994291e9dd2bc0c4e7e5a10ddfbdad550edf903b3b5c1d1";
          format = "zip";
          binPath = "podman-5.8.0/usr/bin/podman";
        };
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        release = releases.${system} or (throw "Unsupported system: ${system}");
      in
      {
        packages = {
          default = self.packages.${system}.podman-remote;

          podman-remote = pkgs.stdenv.mkDerivation {
            pname = "podman-remote";
            inherit version;

            src = pkgs.fetchurl {
              url = "https://github.com/containers/podman/releases/download/v${version}/${release.url}";
              sha256 = release.sha256;
            };

            unpackPhase =
              if release.format == "tar" then
                ''
                  tar -xzf $src
                ''
              else
                ''
                  unzip -q $src
                '';

            installPhase = ''
              mkdir -p $out/bin
              mv ${release.binPath} $out/bin/podman
              chmod +x $out/bin/podman
            '';

            meta = with pkgs.lib; {
              description = "Podman remote client";
              homepage = "https://podman.io";
              license = licenses.asl20;
              platforms = platforms.all;
            };
          };
        };

        apps = {
          podman = flake-utils.lib.mkApp {
            drv = self.packages.${system}.podman-remote;
          };
        };
      }
    )
    // {
      lib = {
        homeManagerModule = import ./home-manager.nix;
        nixosModule = import ./nixos.nix;
      };
    };
}
