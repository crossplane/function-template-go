#!/bin/sh

# This script helps initialize a new function project by
# replacing all instances of function-template-go with the
# name of your function. The scripts accepts two arguments:
# 1. The go module of your function, example: github.com/my-org/my-function
# 2. The path to your function directory

set -e

# Arguments
module_path="$1"
project_dir="$2"
# Extract the last element of the module path using `basename`
function_name=$(basename "${module_path}")

cd "$project_dir" || return

# Replaces function-template-go with the name of your function
# in go.mod
perl -pi -e s,github.com/crossplane/function-template-go,"${module_path}",g go.mod
# in fn.go
perl -pi -e s,github.com/crossplane/function-template-go,"${module_path}",g fn.go
# in examples
perl -pi -e s,function-template-go,"${function_name}",g example/*

echo "Function ${function_name} has been initialised successfully"
