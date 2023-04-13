# help
define cmdline
Choose one of the targets:
	- cmake-3.24.1
	- cuda-12.1
endef
export cmdline

help:
	@echo "$$cmdline"
	
CURRENT_DIR := $(shell pwd)
TARGET_DIR := $(CURRENT_DIR)/target
LOCAL_INST := /usr/local

cmake-3.24.1:
	@mkdir -p $(TARGET_DIR)
	@echo "Downloading binaries"
	@wget https://github.com/Kitware/CMake/releases/download/v3.24.1/cmake-3.24.1-linux-x86_64.tar.gz \
		-O $(TARGET_DIR)/cmake.tar.gz
	@echo "Unpacking binaries"
	@cd $(TARGET_DIR) && \
		tar xvf cmake.tar.gz && \
		rm cmake.tar.gz && \
		rsync -r -a cmake-3.24.1-linux-x86_64/ $(LOCAL_INST) && \
		rm -rf cmake-3.24.1-linux-x86_64
cuda-12.1:
	wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
	mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
	wget https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda-repo-ubuntu1804-12-1-local_12.1.0-530.30.02-1_amd64.deb
	dpkg -i cuda-repo-ubuntu1804-12-1-local_12.1.0-530.30.02-1_amd64.deb
	cp /var/cuda-repo-ubuntu1804-12-1-local/cuda-*-keyring.gpg /usr/share/keyrings/
	apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get -y install cuda
