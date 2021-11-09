#!/bin/sh
# Install Isabelle 2021
ISABIN=isabelle2021-1

# wget https://isabelle.in.tum.de/dist/${ISATARGZ} \
#   && tar -xzf ${ISATARGZ} \
#   && mv ${ISAINSTDIR} /usr/local/ \
#   && ln -s /usr/local/${ISAINSTDIR}/bin/isabelle /usr/local/bin/${ISABIN} \
#   && ln -s /usr/local/bin/${ISABIN} /usr/local/bin/isabelle
tar zxf ${ISATARGZ}

# Get rid of the distribution archive
rm ${ISATARGZ}

ISAINSTDIR=`ls -ld Isabelle*|grep '^d'|sed -e 's/.*\(Isabelle.*\)/\1/'`

mv ${ISAINSTDIR} /usr/local \
	&& ln -s /usr/local/${ISAINSTDIR}/bin/isabelle /usr/local/bin/${ISABIN} \
	&& ln -s /usr/local/bin/${ISABIN} /usr/local/bin/isabelle

# Reuse the SMT solvers embedded into the Isabelle distribution
ln -s /usr/local/${ISAINSTDIR}/contrib/spass-*/*/SPASS /usr/local/bin/SPASS
ln -s /usr/local/${ISAINSTDIR}/contrib/vampire-*/*/vampire /usr/local/bin/vampire

# CVC4 cannot yet be built on arm64
# ln -s /usr/local/${ISAINSTDIR}/contrib/cvc4-1.8/x86_64-linux/cvc4 /usr/local/bin/cvc4

# These ones will be built using the version supported by why3
# ln -s /usr/local/${ISAINSTDIR}/contrib/e-2.5-1/x86_64-linux/eprover /usr/local/bin/eprover
# ln -s /usr/local/${ISAINSTDIR}/contrib/z3-4.4.0pre-3/x86_64-linux/z3 /usr/local/bin/z3

mkdir .isabelle ; cd .isabelle; tar xvf ${HOME}/${ISAPREFS}; rm ${HOME}/${ISAPREFS}
echo 'cp -r /root/.isabelle ${HOME}' >> /root/.novnc_setup

# Reuse the JDK provided with Isabelle for the whole system
ISAJDK=`ls -d /usr/local/${ISAINSTDIR}/contrib/jdk-*/*-linux`
ln -s ${ISAJDK}/bin/java /usr/local/bin/ ; \
    ln -s ${ISAJDK}/bin/javac /usr/local/bin/
