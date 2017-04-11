#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

$DIR/merge-gentoo-staging.py && $DIR/merge-funtoo-staging.py && $DIR/merge-funtoo-production.py
$DIR/2017/merge-funtoo-staging.py && $DIR/2017/merge-funtoo-production.py
