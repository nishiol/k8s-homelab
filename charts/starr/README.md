## Hardware acceleration

This chart supports Intel GPUs using QSV, Intel OpenCL, and `/dev/dri`. AMD and NVIDIA require vendor-specific
container and Jellyfin configuration.

## Media root directories

The `prepare-media-directories` init container creates the Sonarr and Radarr roots and adds `.anchor` files. The
anchors keep the roots from being deleted when the last media directory is removed. Stable root paths are required
for Sonarr/Radarr unmonitoring and Jellyfin's inotify-based real-time monitoring.

Configure the paths and image with `mediaInitializer`, and the shared ownership with `puid` and `pgid`, in
`values.yaml`.
