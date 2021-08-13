docker-cs3asl
=============

Docker image used for teaching in the "Software Science" 3rd year at [CentraleSupélec](http://www.centralesupelec.fr).

Available on [Docker hub](https://hub.docker.com/r/fredblgr/docker-cs3asl)

Source files available on [GitHub](https://github.com/Frederic-Boulanger-UPS/docker-cs3asl).

Based on the work by [Doro Wu](https://github.com/fcwu), see on [Docker](https://hub.docker.com/r/dorowu/ubuntu-desktop-lxde-vnc/)

This image contains Ubuntu 20.04 with an x11vnc server and a VNC client running in your browser with the following tools installed:
* Isabelle 2021 (not for arm64)
* The Coq IDE
* Why3 1.4.0
* Frama-C 23.0
* Metacsl 0.1.2
* Various solvers, among which:
  * Alt-Ergo 2.4.0
  * Z3 4.8.6
  * E 2.6
  * CVC4 1.8 (not for arm64)
* Soufflé 2.0.2
* Eclipse Modeling 2021-06 with:
  * Acceleo 3.7
  * QVT Operational
  * Xpand
  * Xtext
  * C/C++ development tools


Typical usage is:

```
docker run --rm --detach --publish 6080:80 \
           --volume ${PWD}:/workspace:rw \
           --env USERNAME=`id -n -u` \
           --env USERID=`id -u` \
           --env RESOLUTION=1400x900 \
           --name docker-cs3asl fredblgr/docker-cs3asl:2021
```

Very Quick Start
----------------
Run `./start-cs3asl.sh` (available on [GitHub](https://github.com/Frederic-Boulanger-UPS/docker-cs3asl/blob/main/start-cs3asl.sh)), you will have Ubuntu 20.04 in your browser, with the current working directory mounted on /workspace. The container will be removed when it stops, so save your work in /workspace if you want to keep it.

There is a [`start-cs3asl.ps1`](https://github.com/Frederic-Boulanger-UPS/docker-cs3asl/blob/main/start-cs3asl.ps1) script for the PowerShell of Windows. You may have to allow the execution of scripts with the command:

```Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser```.

You browser should display an Ubuntu desktop. Else, check the console for errors and point your web browser at [http://localhost:6080](http://localhost:6080)


Shared directory
----------------

The image is configured to make things easy if your working directory is shared on /workspace in the container:

For instance, Eclipse is configured to create workspaces in /workspace, and the file manager has a bookmark for /workspace.

If you use the `start-cs3asl.sh` script, your user name and user id in the container will be the same as on the host (even if you need sudo to start Docker), so the files created by the container will belong to you.

HTTP Base Authentication
---------------------------

This image provides base access authentication of HTTP via `HTTP_PASSWORD`

```
docker run -p 6080:80 -e HTTP_PASSWORD=mypassword fredblgr/docker-cs3asl:2021
```

Screen Resolution
------------------

The resolution of the virtual desktop can be set by the `RESOLUTION` environment variable, for example

```
docker run --publish 6080:80 --env RESOLUTION=1920x1080 fredblgr/docker-cs3asl:2021
```

Default Desktop User
--------------------

The default user is `root`, the default password is `ubuntu`.
You may change the username, user id and password respectively by setting the `USERNAME`, `USERID` and `PASSWORD` environment variables, for example,

```
docker run --publish 6080:80 --env USERNAME=name --env USERID=42 --env PASSWORD=password fredblgr/docker-cs3asl:2021
```

The `start-cs3asl.sh`script takes care of setting the USERNAME and the USERID variables to your user name and id on the host.

License
==================

Apache License Version 2.0, January 2004 http://www.apache.org/licenses/LICENSE-2.0

Original work by [Doro Wu](https://github.com/fcwu)

Adapted by [Frédéric Boulanger](https://github.com/Frederic-Boulanger-UPS)
