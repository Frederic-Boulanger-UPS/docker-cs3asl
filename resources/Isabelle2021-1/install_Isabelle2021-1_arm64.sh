#!/bin/sh
# Install Isabelle 2021
ISABIN=isabelle2021-1

# Debug
echo "Current working directory is ${PWD}"
echo "Home directory is ${HOME}"

# wget https://isabelle.in.tum.de/dist/${ISATARGZ}
tar zxf ${ISATARGZ}

# Get rid of the distribution archive
rm ${ISATARGZ}

ISAINSTDIR=`ls -ld Isabelle*|grep '^d'|sed -e 's/.*\(Isabelle.*\)/\1/'`

mv ${ISAINSTDIR} /usr/local \
	&& ln -s /usr/local/${ISAINSTDIR}/bin/isabelle /usr/local/bin/${ISABIN} \
	&& ln -s /usr/local/bin/${ISABIN} /usr/local/bin/isabelle

# Update Isabelle.desktop file for name and icon
sed -e 's@^Name=Isabelle-2021$@Name=Isabelle-2021-1@' /usr/share/applications/Isabelle.desktop > /usr/share/applications/Isabelle_tmp.desktop
sedscript="s@^Icon=.*\$@Icon=/usr/local/${ISAINSTDIR}/lib/icons/isabelle.xpm@"
sed -e "${sedscript}" /usr/share/applications/Isabelle_tmp.desktop > /usr/share/applications/Isabelle.desktop
rm /usr/share/applications/Isabelle_tmp.desktop

# Reuse the SMT solvers embedded into the Isabelle distribution
ln -s /usr/local/${ISAINSTDIR}/contrib/spass-*/*/SPASS /usr/local/bin/SPASS
ln -s /usr/local/${ISAINSTDIR}/contrib/vampire-*/*/vampire /usr/local/bin/vampire
# CVC4 cannot yet be built on arm64
# ln -s /usr/local/${ISAINSTDIR}/contrib/cvc4-*/*/cvc4 /usr/local/bin/cvc4
ln -s /usr/local/${ISAINSTDIR}/contrib/verit-*/*/veriT /usr/local/bin/veriT
ln -s /usr/local/${ISAINSTDIR}/contrib/zipperposition-*/*/zipperposition /usr/local/bin/zipperposition
# These ones will be built using the version supported by why3
# ln -s /usr/local/${ISAINSTDIR}/contrib/e-2.5-1/x86_64-linux/eprover /usr/local/bin/eprover
# ln -s /usr/local/${ISAINSTDIR}/contrib/z3-4.4.0pre-3/x86_64-linux/z3 /usr/local/bin/z3

mkdir .isabelle ; cd .isabelle; mv /root/${ISAPREFS} ./${ISAINSTDIR}
# # Rename the settings folder to match the installed version
# ISAPREFSDIR=`ls -ld Isabelle*|grep '^d'|sed -e 's/.*\(Isabelle.*\)/\1/'`
# mv ${ISAPREFSDIR} ${ISAINSTDIR}
# echo 'cp -r /root/.isabelle ${HOME}' >> /root/.novnc_setup

# Reuse the JDK provided with Isabelle for the whole system
ISAJDK=`ls -d /usr/local/${ISAINSTDIR}/contrib/jdk-*/*-linux`
ln -s ${ISAJDK}/bin/java /usr/local/bin/ ; \
    ln -s ${ISAJDK}/bin/javac /usr/local/bin/
