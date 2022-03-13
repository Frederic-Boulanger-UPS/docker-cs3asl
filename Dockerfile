# For which architecture to build (amd64 or arm64)
ARG arch

FROM ubuntu:20.04 as builder
# For which architecture to build (amd64 or arm64)
ARG arch

# Avoid prompts for time zone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

# Fix issue with libGL on Windows
ENV LIBGL_ALWAYS_INDIRECT=1

RUN echo "Building for $arch"

# Update and upgrade apt software
RUN apt-get update && apt-get upgrade -y

# Install some necessary stuff to get and build programs
RUN apt-get install -y x11-apps xdg-utils wget make cmake nano python3-pip

# Build Z3 4.8.6
RUN wget https://github.com/Z3Prover/z3/archive/z3-4.8.6.tar.gz \
	&& tar zxf z3-4.8.6.tar.gz \
	&& cd z3-z3-4.8.6; env PYTHON=python3 ./configure; cd build; make; make install; \
	cd ../..; rm -r z3-*

# Build E prover
# Old 2.0 version at http://wwwlehre.dhbw-stuttgart.de/~sschulz/WORK/E_DOWNLOAD/V_2.0/E.tgz
RUN wget http://wwwlehre.dhbw-stuttgart.de/~sschulz/WORK/E_DOWNLOAD/V_2.6/E.tgz \
	 && tar zxf E.tgz \
	 && cd E; ./configure --prefix=/usr/local; make; make install; \
	 cd ..; rm -r E E.tgz

# Build Soufflé
RUN apt-get install -y autoconf automake bison build-essential clang doxygen flex g++ \
											 git libffi-dev libncurses5-dev libtool libsqlite3-dev make mcpp \
											 python sqlite zlib1g-dev
RUN wget https://github.com/souffle-lang/souffle/archive/refs/tags/2.0.2.tar.gz
RUN tar zxf 2.0.2.tar.gz && rm 2.0.2.tar.gz
RUN cd souffle-2.0.2; sh ./bootstrap; ./configure --prefix=/usr/souffle; make; make install
RUN cd .. ; rm -r souffle-2.0.2
RUN tar zcCf /usr/souffle souffle-202.tgz .

#######################################
FROM fredblgr/ubuntu-novnc:20.04

# For which architecture to build (amd64 or arm64)
ARG arch

# Avoid prompts for time zone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris

# Fix issue with libGL on Windows
ENV LIBGL_ALWAYS_INDIRECT=1
RUN echo "Building for $arch"

# Create HOME directory in case it does not exist (issue on M1 chips)
RUN if [ ! -d ${HOME} ] ; then mkdir ${HOME} ; fi

# Update and upgrade apt software
RUN apt-get update && apt-get upgrade -y

# Install ocaml stuff for why3
RUN apt-get install -y ocaml menhir \
  libnum-ocaml-dev libzarith-ocaml-dev libzip-ocaml-dev \
  libmenhir-ocaml-dev liblablgtk3-ocaml-dev liblablgtksourceview3-ocaml-dev \
  libocamlgraph-ocaml-dev libre-ocaml-dev libjs-of-ocaml-dev

# Install Coq 
RUN apt-get install -y coqide

COPY resources/altergo-240/alt-ergo_$arch /usr/local/bin/alt-ergo
COPY resources/altergo-240/altgr-ergo_$arch /usr/local/bin/altgr-ergo
RUN chmod a+x /usr/local/bin/alt-ergo /usr/local/bin/altgr-ergo

COPY --from=builder /usr/bin/z3 /usr/local/bin/z3
RUN chmod a+x /usr/local/bin/z3

COPY --from=builder /usr/local/bin/eprover /usr/local/bin/eprover
RUN chmod a+x /usr/local/bin/eprover

COPY --from=builder /souffle-202.tgz /usr/local/souffle-202.tgz
RUN cd /usr/local ; tar zxf souffle-202.tgz; rm souffle-202.tgz; cd /
RUN apt install -y mcpp

# Install Isabelle 2021-1
ARG ISADESKTOP=resources/Isabelle2021/Isabelle_$arch.desktop
ARG ISAPREFS=dot_isabelle_2021.tar
ARG ISATARGZ=Isabelle2021-1_linux_$arch.tar.gz
ARG ISAINSTALL=install_Isabelle2021-1_$arch.sh
COPY resources/${ISAINSTALL} /root
COPY resources/downloads/${ISATARGZ} /root
COPY resources/${ISAPREFS} ${HOME}
COPY ${ISADESKTOP} /usr/share/applications/Isabelle.desktop
RUN chmod +x /root/${ISAINSTALL}
RUN env ISATARGZ=${ISATARGZ} ISAPREFS=${ISAPREFS} /root/${ISAINSTALL}

RUN rm -f /root/${ISATARGZ} /root/${ISAINSTALL} ${HOME}/${ISAPREFS}


# Install Why3 when working with Isabelle 2021
RUN wget https://why3.gitlabpages.inria.fr/releases/why3-1.4.0.tar.gz
RUN tar zxf why3-1.4.0.tar.gz && rm why3-1.4.0.tar.gz
COPY resources/why3-fix.tar .
RUN cd why3-1.4.0 && tar --strip-components=1 -xvf ../why3-fix.tar ; rm ../why3-fix.tar
RUN cd why3-1.4.0 && autoconf && ./configure && make
RUN ISAINSTDIR=`ls -d /usr/local/Isabelle*`; echo "/usr/local/lib/why3/isabelle" >> ${ISAINSTDIR}/etc/components

RUN cd why3-1.4.0; make install; make byte; make install-lib ; cd ..; rm -r why3-1.4.0

RUN heapsdir=`ls -d /usr/local/Isabelle*/heaps/polyml-* |sed -e 's=/usr/local/=='`; \
		mv ${HOME}/.isabelle/${heapsdir}/Why3 /usr/local/${heapsdir}/ ;\
    mv ${HOME}/.isabelle/${heapsdir}/log/* /usr/local/${heapsdir}/log/

# Configure Why3 with SMT provers and save the configuration file
RUN why3 config detect && mv ${HOME}/.why3.conf /root/
RUN echo 'cp /root/.why3.conf ${HOME}' >> /root/.novnc_setup

# Configuration of the file manager and the application launcher
COPY resources/dot_config/lxpanel/LXDE/panels/panel_isa_eclipse_firefox /root/.config/lxpanel/LXDE/panels/panel

# Install Eclipse Modeling 2021-09
# https://www.eclipse.org/downloads/packages/release/2021-09/r/eclipse-modeling-tools
# Copy existing configuration containing:
# * Eclipse Modeling 2021-09
# * Acceleo 3.7 from the OBEO Market Place
# * From Install New Software (with all available sites)
#   * All Acceleo
#   * All Additional Interpreters
#   * General Purpose Tools > everything that starts with m2e
#   * Modeling > all QVT operational
#   * Modeling > Xpand SDK
#   * Modeling > Xtext SDK
#   * Programming languages > C/C++ Dev Tools
#   * Programming languages > C/C++ library API doc hover help
#   * Programming languages > C/C++ Unit Testing
#   * Programming languages > Eclipse XML editors and tools
#   * Programming languages > Javascript dev tools
#   * Programming languages > Wild Web developer
#   * Programming languages > Xtend IDE
#   * Web, XML, Java EE and OSGi Enterprise Development > everything that starts with m2e

ENV ECLIPSETGZ=eclipse-modeling-2021-09_$arch.tgz
ENV DOTECLIPSETGZ=dot_eclipse-2021-09_$arch.tgz
ENV ECLIPSEINSTDIR=/usr/local/eclipse-modeling-2021-09
COPY resources/${ECLIPSETGZ} /usr/local/
RUN cd /usr/local; tar zxf ${ECLIPSETGZ} && rm ${ECLIPSETGZ}; \
    ln -s ${ECLIPSEINSTDIR}/eclipse /usr/local/bin/eclipse
COPY resources/Eclipse-2021-09.desktop /usr/share/applications/Eclipse.desktop
COPY resources/${DOTECLIPSETGZ} /root/
RUN cd /root ; tar zxf ${DOTECLIPSETGZ} ; rm ${DOTECLIPSETGZ}
RUN echo 'cp -r /root/.eclipse ${HOME}' >> /root/.novnc_setup

# Install Frama-C
RUN apt-get install -y yaru-theme-icon
RUN wget https://frama-c.com/download/frama-c-23.0-Vanadium.tar.gz
RUN tar zxf frama-c-23.0-Vanadium.tar.gz && rm frama-c-23.0-Vanadium.tar.gz; \
    cd frama-c-23.0-Vanadium; autoconf; ./configure; make; make install ; \
		cd ..; rm -rf frama-c-23.0-Vanadium

# Install Metacsl
RUN wget https://git.frama-c.com/pub/meta/-/archive/0.1.2/meta-0.1.2.tar.gz \
  	&& tar zxf meta-0.1.2.tar.gz && rm meta-0.1.2.tar.gz \
  	&& cd meta-0.1.2 \
  	&& autoconf && ./configure && make && make install ; \
  	cd ..; rm -rf meta-0.1.2

RUN apt-get update; apt-get upgrade -y

RUN apt-get install at-spi2-core

RUN apt-get install -y git xdg-utils wget make nano

RUN apt autoremove && apt autoclean

RUN rm -rf /tmp/*
