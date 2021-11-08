#!/bin/sh
# Install Isabelle 2021
ISATARGZ=Isabelle2021_linux.tar.gz
ISABIN=isabelle2021
ISAJDK=/usr/local/Isabelle2021/contrib/jdk-15.0.2+7/x86_64-linux

wget https://isabelle.in.tum.de/dist/${ISATARGZ} \
  && tar -xzf ${ISATARGZ} \
  && mv ${ISAINSTDIR} /usr/local/ \
  && ln -s /usr/local/${ISAINSTDIR}/bin/isabelle /usr/local/bin/${ISABIN} \
  && ln -s /usr/local/bin/${ISABIN} /usr/local/bin/isabelle

# Reuse the SMT solvers embedded into the Isabelle distribution
ln -s /usr/local/${ISAINSTDIR}/contrib/spass-3.8ds-2/x86_64-linux/SPASS /usr/local/bin/SPASS
ln -s /usr/local/${ISAINSTDIR}/contrib/vampire-4.2.2/x86_64-linux/vampire /usr/local/bin/vampire
ln -s /usr/local/${ISAINSTDIR}/contrib/cvc4-1.8/x86_64-linux/cvc4 /usr/local/bin/cvc4
# These ones will be built using the version supported by why3
# ln -s /usr/local/${ISAINSTDIR}/contrib/e-2.5-1/x86_64-linux/eprover /usr/local/bin/eprover
# ln -s /usr/local/${ISAINSTDIR}/contrib/z3-4.4.0pre-3/x86_64-linux/z3 /usr/local/bin/z3

# Get rid of the distribution archive
rm ${ISATARGZ}

mkdir .isabelle ; cd .isabelle; tar xvf ${HOME}/${ISAPREFS}; rm ${HOME}/${ISAPREFS}
echo 'cp -r /root/.isabelle ${HOME}' >> /root/.novnc_setup

# Reuse the JDK provided with Isabelle for the whole system
ln -s ${ISAJDK}/bin/java /usr/local/bin/ ; \
    ln -s ${ISAJDK}/bin/javac /usr/local/bin/
