#!/bin/bash

# Load `nvm`.
# Why need load `nvm` when setup a new shell session:
# https://github.com/creationix/nvm/issues/521#issuecomment-55017400
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# Now you can use `nvm` if need.

npm install --registry=http://registry.npm.pt.mi.com/
npm run goku
