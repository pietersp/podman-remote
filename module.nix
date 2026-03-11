{ lib }:

let
  mkOpt = lib // { mkOption = lib.mkOption or (x: x); };
in
{
  options.programs.podman-remote = {
    enable = lib.mkEnableOption "podman-remote client";

    package = lib.mkOption {
      description = "The podman-remote package to use";
    };

    socketPath = lib.mkOption {
      type = lib.types.str;
      default = "unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock";
      description = "Path to the Podman socket. Override for non-default machines or rootless mode";
      example = "unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-user.sock";
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Remote hostname for SSH connections (leave empty for Unix socket)";
      example = "192.168.1.100";
    };

    compose = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable podman-compose support";
      };
    };
  };
}
