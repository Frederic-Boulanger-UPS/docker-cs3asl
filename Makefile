.PHONY: build manifest run debug push save clean clobber

REPO    = fredblgr/
NAME    = docker-3asl
#ARCH    = `uname -m`
TAG     = 2021
ARCH   := $$(arch=$$(uname -m); if [[ $$arch == "x86_64" ]]; then echo amd64; else echo $$arch; fi)
RESOL   = 1440x900
ARCHS   = amd64 arm64
IMAGES := $(ARCHS:%=$(REPO)$(NAME):$(TAG)-%)
PLATFORMS := $$(first="True"; for a in $(ARCHS); do if [[ $$first == "True" ]]; then printf "linux/%s" $$a; first="False"; else printf ",linux/%s" $$a; fi; done)
# Temporarily do  not tag the image with its architecture.
# We know how to build only on x86_64
#ARCHIMAGE := $(REPO)$(NAME):$(TAG)-$(ARCH)
ARCHIMAGE := $(REPO)$(NAME):$(TAG)

help:
	@echo "# Available targets:"
	@echo "#   - build: build docker image"
	@echo "#   - clean: clean docker build cache"
	@echo "#   - run: run docker container"
	@echo "#   - push: push docker image to docker hub"

resources/dot_isabelle_2021.tar: resources/dot_isabelle_2021/*
	tar cvCf resources/dot_isabelle_2021 resources/dot_isabelle_2021.tar --exclude .DS_Store .

# Build image
build: resources/why3-fix.tar resources/dot_isabelle_2021.tar
	@echo "Building $(ARCHIMAGE) for $(ARCH)"
	docker build --build-arg arch=$(ARCH) --tag $(ARCHIMAGE) .
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
	docker run --privileged --rm --interactive --tty \
    --volume ${PWD}:/workspace:rw \
    --env user="`id -n -u`" --env userid="`id -u`" \
    ubuntu:20.04 \
    bash /workspace/resources/altergo-240/build-alt-ergo.sh
