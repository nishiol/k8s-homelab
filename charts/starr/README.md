Only works for Intel GPUs now. TODO: support different kind of GPUs

Add some stub file into Sonarr and Radarr root folders to make 'Unmonitor Deleted Movies'
feature work as well as Jellyfin's 'Enable real time monitoring' feature when there is only one movie/tv in the library.
For example, 

```shell
touch data/media/movies/.anchor
touch data/media/tv/.anchor
```

TODO: place all actions above to initContainer