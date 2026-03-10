{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.podman-remote;
in
{
  options.programs.podman-remote = {
    enable = mkEnableOption "podman-remote client";

    package = mkOption {
      type = types.package;
      description = "The podman-remote package to use";
      default = pkgs.podman-remote;
    };

    socketPath = mkOption {
      type = types.str;
      default = "unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock";
      description = "Path to the Podman socket. Override for non-default machines or rootless mode";
      example = "unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-user.sock";
    };

    hostname = mkOption {
      type = types.str;
      default = "";
      description = "Remote hostname for SSH connections (leave empty for Unix socket)";
      example = "192.168.1.100";
    };
  };

  config = mkIf cfg.enable {
    environment.sessionVariables = {
      PODMAN_HOST = if cfg.hostname != "" then "ssh://${cfg.hostname}" else cfg.socketPath;
    };

    environment.systemPackages = [ cfg.package ];

    programs.bash.initExtra =
      mkIf (cfg.hostname == "") ''
        alias podman=${cfg.package}/bin/podman
      ''
      + mkIf (cfg.hostname != "") ''
        alias podman='PODMAN_HOST=ssh://${cfg.hostname} ${cfg.package}/bin/podman'
      '';
  };
}
