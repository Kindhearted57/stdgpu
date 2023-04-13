define cmdline
Please choose one of the specific commands:
  - build : build the docker image
  - once  : probe once into the docker image and discard the changes
  - script: run a script over the docker image
endef
export cmdline

help:
	@echo "$$cmdline"
# paths
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(dir $(mkfile_path))
project_dir := $(realpath $(current_dir)/..)

tag = my-cuda-image

build:
	 docker build . -t $(tag)

once:
	@docker run --rm \
		-v $(project_dir):/project \
		-it \
		--entrypoint /bin/bash \
		$(tag)
