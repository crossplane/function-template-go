#!/bin/sh

# This script helps initialize a new function project by
# replacing all instances of function-template-go with the
# name of your function. The scripts accepts two arguments:
# 1. The name of your function
# 2. The path to your function directory

set -e

cd "$2" || return

# Replace function-template-go with the name of your function
# in go.mod
perl -pi -e s,function-template-go,"$1",g go.mod
# in fn.go
perl -pi -e s,function-template-go,"$1",g fn.go
# in examples
perl -pi -e s,function-template-go,"$1",g example/*

echo "Function $1 has been initialised successfully"
