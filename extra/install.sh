#!/bin/bash

# get directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

GUI_WRAPPER_PATH="/usr/bin/namefix-gui"
CLI_WRAPPER_PATH="/usr/bin/namefix"

echo "Script directory: ${SCRIPT_DIR}"	

echo install script

echo set execution bits
chmod a+x "${SCRIPT_DIR}"/*.par

echo remove old versions
sudo rm -vf /usr/bin/namefix*

echo "setup CLI & GUI wrappers"
sudo tee ${CLI_WRAPPER_PATH} > /dev/null <<EOF
#!/bin/bash
parl "${SCRIPT_DIR}/namefix-cli.par" "\$@"
EOF
sudo chmod a+x ${CLI_WRAPPER_PATH}

sudo tee ${GUI_WRAPPER_PATH} > /dev/null <<EOF
#!/bin/bash
parl "${SCRIPT_DIR}/namefix-gui.par" "\$@"
EOF
sudo chmod a+x ${GUI_WRAPPER_PATH}

