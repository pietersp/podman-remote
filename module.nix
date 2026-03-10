{ lib }:

let
  mkOpt = lib.mkOption or lib.mkOption;
  mkEnable = lib.mkEnableOption or lib.mkEnableOption;
  mkIf = lib.mkIf or lib.mkIf;
  types = lib.types or {};
in
{
  options.programs.podman-remote = {
    enable = (mkEnable or mkOpt) "podman-remote client";

    package = mkOpt {
      type = types.package or lib.mkOptionType { name = "package"; };
      description = "The podman-remote package to use";
    };

    socketPath = mkOpt {
      type = types.str or lib.mkOptionType { name = "string"; };
      default = "unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock";
      description = "Path to the Podman socket. Override for non-default machines or rootless mode";
      example = "unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-user.sock";
    };

    hostname = mkOpt {
      type = types.str or lib.mkOptionType { name = "string"; };
      default = "";
      description = "Remote hostname for SSH connections (leave empty for Unix socket)";
      example = "192.168.1.100";
    };
  };
}
