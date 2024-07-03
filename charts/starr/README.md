Only works for Intel GPUs now. TODO: support different kind of GPUs

Add some stub file into Sonarr and Radarr root folders to make 'Unmonitor Deleted Movies'
feature work as well as Jellyfin's 'Enable real time monitoring' feature when there is only one movie/tv in the library.
For example, 

```shell
touch data/media/movies/.anchor
touch data/media/tv/.anchor
```


Put `recyclarr/radarr.yaml` and `recyclarr/sonarr.yaml` into `/config/configs` directory of `recyclarr` container to
sync [TRaSH Guides](https://trash-guides.info/) Quality Profiles (don't forget to update `base_url` and `api_key`
values!).

TODO: place all actions above to initContainer/ConfigMap