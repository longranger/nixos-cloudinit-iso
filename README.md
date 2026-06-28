# NixOS Cloud-Init ISO

A minimal, reproducible NixOS installation media configured to bootstrap virtual and physical machines using `cloud-init`. This repository contains a pure Nix Flake that builds a universal, headless installer ISO capable of parsing metadata drives to initialize network settings and inject SSH keys, preparing hosts for configuration tools like Colmena.

---

## Usage

### Local Build Commands

To evaluate the flake and compile the ISO locally, execute the following commands within the repository directory:

```bash
nix build
```

Upon a successful build, a standard `./result` symlink is generated in the root directory. The output ISO artifact is located at:

```bash
ls -l result/iso/
```

### Automation Architecture

The pipeline automates the provisioning of high-availability infrastructure:

```
[ Git / Flake Source ] ──> Triggers GitHub Actions / CI
                                   │
                                   ▼
[ Native Nix Build ] ────> Compiles minimal ISO with Cloud-Init
                                   │
                                   ▼
[ GitHub Release ] ──────> Hosts the static 'latest' ISO artifact
                                   │
                                   ▼
[ OpenTofu / TF ] ───────> Pulls ISO to Hypervisor, creates VM,
                           and attaches Cloud-Init metadata
```

---

## Continuous Integration

The repository includes a GitHub Actions workflow (`.github/workflows/build-iso.yml`) designed to:

1. Rebuild the ISO automatically on a weekly schedule to incorporate the latest upstream security patches and updates from `nixos-unstable`.
2. Rebuild on every push to the `main` branch.
3. Publish the final compilation artifact to a rolling GitHub release tag named `latest`.
