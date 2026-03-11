# podman-remote

[Nix flake](https://nixos.wiki/wiki/Flakes) providing the Podman remote client binary.

## What is this?

This flake builds the `podman-remote` binary from GitHub releases. I use podman on my Windows machine together with WSL need podman to be accessible from my WSL instance [See this](https://podman-desktop.io/docs/podman/accessing-podman-from-another-wsl-instance) . To avoid having to manually install the tarball on my WSL instance I made this. The tarball contains a **statically linked** Podman client that can connect to a remote Podman machine over SSH or Unix socket. This downloads the tarball and makes it available to your WSL instance using Nix / Home manager.

## Use case

This is useful when you want to access a Podman machine running on a different machine or VM. Common scenarios:

- **WSL**: Access Podman Desktop's Podman machine from another WSL distribution on Windows
- **Remote servers**: Connect to a Podman instance running on a remote Linux server

## Quick start (recommended)

**Note:** `podman compose` support is enabled by default. Set `compose = false` to disable it.

Add the following to your flake inputs:
```nix
{
  inputs.podman-remote.url = "github:pietersp/podman-remote-nix";
}
```

Add to your home-manager configuration (e.g., `home/pieter/default.nix`):

```nix
{ inputs, ... }: {
  imports = [ "${inputs.podman-remote}/home-manager.nix" ];

  programs.podman-remote = {
    enable = true;
    package = inputs.podman-remote.packages.x86_64-linux.podman-remote;
  };
}
```

Or for NixOS module configuration:

```nix
{ inputs, ... }: {
  imports = [ "${inputs.podman-remote}/nixos.nix" ];

  programs.podman-remote = {
    enable = true;
    package = inputs.podman-remote.packages.x86_64-linux.podman-remote;
  };
}
```

This will:
- Set `PODMAN_HOST` to connect to WSL's podman-machine-default by default
- Install the podman-remote binary
- Install podman-compose by default (set `compose.enable = false` to disable)

## Configuration options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable podman-remote |
| `package` | package | `null` | The podman-remote package (from flake) |
| `socketPath` | string | see below | Path to Podman socket |
| `hostname` | string | "" | Remote SSH host (leave empty for Unix socket) |
| `compose.enable` | bool | `true` | Enable podman-compose support |

**Default socket path:** `unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock`

The `package` option requires the package from the flake, e.g.:
```nix
package = inputs.podman-remote.packages.x86_64-linux.podman-remote;
```

### Examples

Rootless Podman in WSL:
```nix
programs.podman-remote = {
  enable = true;
  package = inputs.podman-remote.packages.x86_64-linux.podman-remote;
  socketPath = "unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-user.sock";
};
```

SSH to remote host:
```nix
programs.podman-remote = {
  enable = true;
  package = inputs.podman-remote.packages.x86_64-linux.podman-remote;
  hostname = "192.168.1.100";
};
```

Disable podman-compose:
```nix
programs.podman-remote = {
  enable = true;
  package = inputs.podman-remote.packages.x86_64-linux.podman-remote;
  compose.enable = false;
};
```

## Installation (without module)

### Via nix profile

```bash
nix profile install github:pietersp/podman-remote-nix
```

### Using nix shell

```bash
nix shell github:pietersp/podman-remote-nix
podman --version
podman compose up
```

### Using nix run

```bash
nix run github:pietersp/podman-remote-nix -- --version
```

## Overlays

You can use this as an overlay to replace the Podman package:

```nix
{
  inputs = {
    podman-remote.url = "github:pietersp/podman-remote-nix";
  };

  nixpkgs.overlays = [
    (self: super: {
      podman-remote = inputs.podman-remote.packages.${self.system}.podman-remote;
    })
  ];
}
```

## Manual setup (legacy)

If not using the module, you can set `PODMAN_HOST` manually:

```bash
# ~/.bashrc or ~/.zshrc
export PODMAN_HOST=unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-root.sock
```

Or for rootless:
```bash
export PODMAN_HOST=unix:///mnt/wsl/podman-sockets/podman-machine-default/podman-user.sock
```

## Pinning versions

Users can pin to a specific version in their `inputs`:

```nix
{
  inputs = {
    # Pin to a specific tag
    podman-remote.url = "github:pietersp/podman-remote-nix/v5.8.0";

    # Or pin to a specific commit
    # podman-remote.url = "github:pietersp/podman-remote-nix";
    # podman-remote.ref = "main";
    # podman-remote_rev = "abc123...";
  };
}
```

## Maintainer Notes

### Updating to a new Podman version

1. **Find the new version** at https://github.com/containers/podman/releases/latest

2. **Download and calculate SHA256 hashes**:
   ```bash
   # Linux
   curl -sL https://github.com/containers/podman/releases/download/vVERSION/podman-remote-static-linux_amd64.tar.gz | sha256sum
   curl -sL https://github.com/containers/podman/releases/download/vVERSION/podman-remote-static-linux_arm64.tar.gz | sha256sum
   
   # macOS
   curl -sL https://github.com/containers/podman/releases/download/vVERSION/podman-remote-release-darwin_amd64.zip | sha256sum
   curl -sL https://github.com/containers/podman/releases/download/vVERSION/podman-remote-release-darwin_arm64.zip | sha256sum
   ```

3. **Convert hashes to SRI format**:
   ```bash
   nix hash to-sri --type sha256 <hex-hash>
   ```

4. **Update `flake.nix`**:
   - Change `version` to new version
   - Update all 4 SHA256 hashes in `releases`

5. **Verify builds work**:
   ```bash
   nix build .#podman-remote
   ./result/bin/podman --version
   ```

6. **Create GitHub release**:
   ```bash
   git add -A
   git commit -m "Update to vVERSION"
   git tag vVERSION
   git push origin main --tags
   ```

### Verification checklist before releasing
- [ ] All 4 platforms build successfully
- [ ] Binary runs: `./result/bin/podman --version`
- [ ] Binary is statically linked: `file result/bin/podman` shows "statically linked"
- [ ] Tag pushed to GitHub

## Supported platforms

- Linux: x86_64, aarch64
- macOS: x86_64, aarch64
