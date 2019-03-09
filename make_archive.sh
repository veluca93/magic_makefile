#!/bin/bash

TMPDIR=$(mktemp -d)

cleanup() {
  rm -rf $TMPDIR
}

trap cleanup EXIT

TGT=$(realpath $1)

shift

for SOURCE in "$@"
do
  if [[ $SOURCE == *.tar ]]
  then
    tar xf $SOURCE -C $TMPDIR
  else
    mkdir -p $TMPDIR/$(dirname $SOURCE)
    cp $SOURCE $TMPDIR/$SOURCE
  fi
done

cd $TMPDIR

tar c . > $TGT
