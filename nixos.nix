{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;
  cfg = config.programs.podman-remote;
in
{
  options.programs.podman-remote = {
    enable = mkEnableOption "podman-remote client";

    package = mkPackageOption pkgs "podman-remote" { nullable = true; };

    socketPath = mkOption {
      type = lib.types.str;
      default = "unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock";
      description = "Path to the Podman socket. Override for non-default machines or rootless mode";
      example = "unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-user.sock";
    };

    hostname = mkOption {
      type = lib.types.str;
      default = "";
      description = "Remote hostname for SSH connections (leave empty for Unix socket)";
      example = "192.168.1.100";
    };

    compose = {
      enable = mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable podman-compose support";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = mkIf (cfg.package != null) [ cfg.package ]
      ++ lib.optionals cfg.compose.enable [ pkgs.podman-compose ];

    environment.sessionVariables = {
      PODMAN_HOST = if cfg.hostname != "" then "ssh://${cfg.hostname}" else cfg.socketPath;
    };
  };
}
