image_name := "szos"
default_tag := "latest"

default:
    just --list

build target_image=image_name tag=default_tag:
    podman build --pull=newer -t {{ target_image }}:{{ tag }} .

build-local:
    just build localhost/{{ image_name }} {{ default_tag }}

push registry image=image_name tag=default_tag:
    podman tag {{ image_name }}:{{ tag }} {{ registry }}/{{ image }}:{{ tag }}
    podman push {{ registry }}/{{ image }}:{{ tag }}

inspect target_image=image_name tag=default_tag:
    podman image inspect {{ target_image }}:{{ tag }}
