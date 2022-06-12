.PHONY: build manifest run debug push save clean clobber buildaltergo buildprovers

REPO    = fredblgr/
NAME    = docker-cs3asl
TAG     = 2022
ARCH   := $$(arch=$$(uname -m); if [ $$arch = "x86_64" ]; then echo amd64; elif [ $$arch = "aarch64" ]; then echo arm64; else echo $$arch; fi)
RESOL   = 1440x900
ARCHS   = amd64 arm64
IMAGES := $(ARCHS:%=$(REPO)$(NAME):$(TAG)-%)
PLATFORMS := $$(first="True"; for a in $(ARCHS); do if [[ $$first == "True" ]]; then printf "linux/%s" $$a; first="False"; else printf ",linux/%s" $$a; fi; done)

ARCHIMAGE := $(REPO)$(NAME):$(TAG)-$(ARCH)

help:
	@echo "# Available targets:"
	@echo "#   - build: build docker image"
	@echo "#   - clean: clean docker build cache"
	@echo "#   - run: run docker container"
	@echo "#   - push: push docker image to docker hub"

# Build image
build:
	@echo "Building $(ARCHIMAGE) for $(ARCH)"
	docker build --pull --build-arg arch=$(ARCH) --tag $(ARCHIMAGE) .
	@danglingimages=$$(docker images --filter "dangling=true" -q); \
	if [[ $$danglingimages != "" ]]; then \
	  docker rmi $$(docker images --filter "dangling=true" -q); \
	fi

# Safe way to build multiarchitecture images:
# - build each image on the matching hardware, with the -$(ARCH) tag
# - push the architecture specific images to Dockerhub
# - build a manifest list referencing those images
# - push the manifest list so that the multiarchitecture image exist
manifest:
	docker manifest create $(REPO)$(NAME):$(TAG) $(IMAGES)
	@for arch in $(ARCHS); \
	 do \
	   echo docker manifest annotate --os linux --arch $$arch $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)-$$arch; \
	   docker manifest annotate --os linux --arch $$arch $(REPO)$(NAME):$(TAG) $(REPO)$(NAME):$(TAG)-$$arch; \
	 done
	docker manifest push $(REPO)$(NAME):$(TAG)

rmmanifest:
	docker manifest rm $(REPO)$(NAME):$(TAG)


push:
	docker push $(ARCHIMAGE)

save:
	docker save $(ARCHIMAGE) | gzip > $(NAME)-$(TAG)-$(ARCH).tar.gz

# Clear caches
clean:
	docker builder prune

clobber:
	docker rmi $(REPO)$(NAME):$(TAG) $(ARCHIMAGE)
	docker rmi $(REPO)$(NAMEX):$(TAG) $(ARCHIMAGEX)
	docker builder prune --all

run:
	docker run --rm --detach \
		--env="USERNAME=`id -n -u`" --env="USERID=`id -u`" \
		--volume ${PWD}:/workspace:rw \
		--publish 6080:80 \
		--name $(NAME) \
		--env "RESOLUTION=$(RESOL)" \
		$(ARCHIMAGE)
	sleep 5
	open http://localhost:6080 || xdg-open http://localhost:6080 || echo "http://localhost:6080"

runasubuntu:
	docker run --rm --detach \
		--env="USERNAME=ubuntu" \
		--volume ${PWD}:/workspace:rw \
		--publish 6080:80 \
		--name $(NAME) \
		--env "RESOLUTION=$(RESOL)" \
		$(ARCHIMAGE)
	sleep 5
	open http://localhost:6080 || xdg-open http://localhost:6080 || echo "http://localhost:6080"

runasroot:
	docker run --rm --detach \
		--volume ${PWD}:/workspace:rw \
		--publish 6080:80 \
		--name $(NAME) \
		--env "RESOLUTION=$(RESOL)" \
		$(ARCHIMAGE)
	sleep 5
	open http://localhost:6080 || xdg-open http://localhost:6080 || echo "http://localhost:6080"

runpriv:
	docker run --rm --interactive --tty --privileged \
		--env "USERNAME=`id -n -u`" --env "USERID=`id -u`" --env "PASSWORD=ubuntu" \
		--volume ${PWD}:/workspace:rw \
		--publish 6080:80 \
		--name $(NAME) \
		--env "RESOLUTION=$(RESOL)" \
		$(ARCHIMAGE)
	sleep 5
	open http://localhost:6080 || xdg-open http://localhost:6080 || echo "http://localhost:6080"

debug:
	docker run --rm --tty --interactive \
		--volume ${PWD}:/workspace:rw \
		--env="USERNAME=`id -n -u`" --env="USERID=`id -u`" \
		--publish 6080:80 \
		--name $(NAME) \
		--env "RESOLUTION=$(RESOL)" \
		--entrypoint=bash \
		$(ARCHIMAGE)

buildaltergo:
	cd docker_build_alt-ergo ; ./docker_build_alt-ergo.sh

buildprovers:
	cd docker_build_provers ; ./docker_build_provers.sh

