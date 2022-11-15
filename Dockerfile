FROM fredblgr/ubuntu-novnc:22.04

# For which architecture to build (amd64 or arm64)
ARG arch

# Avoid prompts for time zone
# ENV DEBIAN_FRONTEND=noninteractive
# ENV TZ=Europe/Paris

# Fix issue with libGL on Windows
ENV LIBGL_ALWAYS_INDIRECT=1
RUN echo "Building for $arch"

# Create HOME directory in case it does not exist (issue on M1 chips)
# RUN if [ ! -d ${HOME} ] ; then mkdir ${HOME} ; fi

# Install Isabelle 2021-1
ARG ISAVERSION=Isabelle2021-1
ARG ISADESKTOP=Isabelle_$arch.desktop
ARG ISAPREFS=dot_Isabelle2021-1
ARG ISATARGZ=${ISAVERSION}_linux_$arch.tar.gz
ARG ISAINSTALL=install_Isabelle2021-1_$arch.sh
COPY resources/${ISAVERSION}/${ISAINSTALL} /root
COPY resources/downloads/${ISATARGZ} /root
COPY resources/${ISAVERSION}/${ISAPREFS} /root/${ISAPREFS}
COPY resources/${ISAVERSION}/${ISADESKTOP} /usr/share/applications/Isabelle.desktop
RUN chmod +x /root/${ISAINSTALL}
RUN env ISATARGZ=${ISATARGZ} ISAPREFS=${ISAPREFS} /root/${ISAINSTALL}

RUN rm -rf /root/${ISATARGZ} /root/${ISAINSTALL}

# # Install Isabelle 2022 (why3 1.5.0 does not work with this version)
# ARG ISAVERSION=Isabelle2022
# ARG ISADESKTOP=Isabelle_$arch.desktop
# ARG ISAPREFS=dot_Isabelle2022
# ARG ISATARGZ=${ISAVERSION}_linux_$arch.tar.gz
# ARG ISAINSTALL=install_Isabelle2022_$arch.sh
# COPY resources/${ISAVERSION}/${ISAINSTALL} /root
# COPY resources/downloads/${ISATARGZ} /root
# COPY resources/${ISAVERSION}/${ISAPREFS} /root/${ISAPREFS}
# COPY resources/${ISAVERSION}/${ISADESKTOP} /usr/share/applications/Isabelle.desktop
# RUN chmod +x /root/${ISAINSTALL}
# RUN env ISATARGZ=${ISATARGZ} ISAPREFS=${ISAPREFS} /root/${ISAINSTALL}
# 
# RUN rm -rf /root/${ISATARGZ} /root/${ISAINSTALL}

# Install ocaml stuff for why3
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
	ocaml menhir libnum-ocaml-dev libmenhir-ocaml-dev libzarith-ocaml-dev \
	libzip-ocaml-dev liblablgtk3-ocaml-dev liblablgtksourceview3-ocaml-dev \
	libocamlgraph-ocaml-dev libre-ocaml-dev libjs-of-ocaml-dev

# Install Coq 
RUN apt-get install -y coqide

COPY docker_build_alt-ergo/alt-ergo_$arch /usr/local/bin/alt-ergo
# COPY docker_build_alt-ergo/altgr-ergo_$arch /usr/local/bin/altgr-ergo
RUN chmod a+x /usr/local/bin/alt-ergo
# RUN chmod a+x /usr/local/bin/altgr-ergo

COPY docker_build_provers/z3_$arch /usr/local/bin/z3
RUN chmod a+x /usr/local/bin/z3

COPY docker_build_provers/eprover_$arch /usr/local/bin/eprover
RUN chmod a+x /usr/local/bin/eprover

COPY docker_build_provers/souffle-2.3_$arch.tgz /usr/local/souffle-2.3.tgz
RUN cd /usr/local ; tar zxf souffle-2.3.tgz; rm souffle-2.3.tgz; cd /
RUN apt install -y mcpp

# Install Why3 when working with Isabelle 2021-1
RUN wget https://why3.gitlabpages.inria.fr/releases/why3-1.5.1.tar.gz
RUN tar zxf why3-1.5.1.tar.gz && rm why3-1.5.1.tar.gz
COPY resources/why3-150-fix/isabelle.ml why3-1.5.1/src/printer/isabelle.ml
# COPY resources/why3.ML.2021-1 why3-1.5.1/lib/isabelle/why3.ML.2021-1
RUN cd why3-1.5.1 && ./configure && make
RUN ISAINSTDIR=`ls -d /usr/local/Isabelle*`; echo "/usr/local/lib/why3/isabelle" >> ${ISAINSTDIR}/etc/components

RUN cd why3-1.5.1; make install; make byte; make install-lib ; cd ..; rm -r why3-1.5.1

RUN heapsdir=`ls -d /usr/local/Isabelle*/heaps/polyml-* |sed -e 's=/usr/local/=='`; \
	mv ${HOME}/.isabelle/${heapsdir}/Why3 /usr/local/${heapsdir}/ ;\
    mv ${HOME}/.isabelle/${heapsdir}/log/* /usr/local/${heapsdir}/log/

# Configure Why3 with SMT provers and save the configuration file
RUN why3 config detect && mv ${HOME}/.why3.conf /root/
# RUN echo 'cp /root/.why3.conf ${HOME}' >> /root/.novnc_setup

# Install Frama-C
RUN apt-get install -y yaru-theme-icon autoconf graphviz \
                       libppx-import-ocaml-dev libppx-deriving-ocaml-dev \
                       libppx-deriving-yojson-ocaml-dev swi-prolog at-spi2-core
RUN wget https://frama-c.com/download/frama-c-25.0-Manganese.tar.gz
RUN tar zxf frama-c-25.0-Manganese.tar.gz && rm frama-c-25.0-Manganese.tar.gz; \
    cd frama-c-25.0-Manganese; autoconf; ./configure; make; make install ; \
    cd ..; rm -rf frama-c-25.0-Manganese

# Install Metacsl
RUN wget https://git.frama-c.com/pub/meta/-/archive/0.3/meta-0.3.tar.gz \
  	&& tar zxf meta-0.3.tar.gz && rm meta-0.3.tar.gz \
  	&& cd meta-0.3 \
  	&& autoconf && ./configure && make && make install ; \
  	cd ..; rm -rf meta-0.3*

# Install Eclipse Modeling 2022-09
# https://www.eclipse.org/downloads/packages/release/2022-09/r/eclipse-modeling-tools
# Copy existing configuration containing:
# * Eclipse Modeling 2022-09
# * From Install New Software (with all available sites)
#   > Modeling
#   * 	Acceleo
#   * OCL Examples and Editors SDK
#   * 	QVT Operational *
#   * 	Xtext Complete SDK
#   > Programming Languages
#   * 	C/C++ Development Tools
#   * 	C/C++ Library API Documentation Hover Help
#   * 	C/C++ LLVM-Family Compiler Build Support (on MacOS)
#   * 	C/C++ Unit Testing Support
#   * 	Eclipse XML Editors and Tools
#   * 	JavaScript Development Tools
#   * 	PHP Development Tools (PDT)
#   * 	Wild Web Developer HTML, CSS, JSON, Yaml, JavaScript, TypeScript, Node tools
#   *	  Xtend IDE
#   > Web, XML, Java EE and OSGi Enterprise Development
#   *	  Eclipse XSL Developer Tools

ARG ECLIPSEVERSION=Eclipse-2022-09
ENV ECLIPSETGZ=eclipse-modeling-2022-09_$arch.tgz
ENV DOTECLIPSETGZ=dot_eclipse-modeling-2022-09_$arch.tgz
ENV ECLIPSEINSTDIR=/usr/local/eclipse-modeling-2022-09
COPY resources/${ECLIPSEVERSION}/${ECLIPSETGZ} /usr/local/
RUN cd /usr/local; tar zxf ${ECLIPSETGZ} && rm ${ECLIPSETGZ}; \
    ln -s ${ECLIPSEINSTDIR}/eclipse /usr/local/bin/eclipse
COPY resources/${ECLIPSEVERSION}//${ECLIPSEVERSION}.desktop /usr/share/applications/Eclipse.desktop
COPY resources/${ECLIPSEVERSION}/${DOTECLIPSETGZ} /root/
RUN cd /root ; tar zxf ${DOTECLIPSETGZ} ; rm ${DOTECLIPSETGZ}
# RUN echo 'cp -r /root/.eclipse ${HOME}' >> /root/.novnc_setup

# Configuration of the file manager and the application launcher
COPY resources/dot_config/lxpanel/LXDE/panels/panel_isa_eclipse_firefox /root/.config/lxpanel/LXDE/panels/panel

RUN apt autoremove && apt autoclean

RUN rm -rf /tmp/*
