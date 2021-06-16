#!/usr/bin/sh
echo $1
pushd /var/db/repos/qubes/$1
repoman manifest
popd
