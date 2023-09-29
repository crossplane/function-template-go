# set the shell to bash always
SHELL := /usr/bin/env bash

# Set the host's OS. Only linux and darwin supported for now
HOSTOS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ifeq ($(filter darwin linux,$(HOSTOS)),)
$(error build only supported on linux and darwin host currently)
endif

# Set the host's arch.
HOSTARCH := $(shell uname -m)

# If SAFEHOSTARCH and TARGETARCH have not been defined yet, use HOST
ifeq ($(origin SAFEHOSTARCH),undefined)
SAFEHOSTARCH := $(HOSTARCH)
endif
ifeq ($(origin TARGETARCH), undefined)
TARGETARCH := $(HOSTARCH)
endif

# Automatically translate x86_64 to amd64
ifeq ($(HOSTARCH),x86_64)
SAFEHOSTARCH := amd64
TARGETARCH := amd64
endif

# Automatically translate aarch64 to arm64
ifeq ($(HOSTARCH),aarch64)
SAFEHOSTARCH := arm64
TARGETARCH := arm64
endif

ifeq ($(filter amd64 arm64 ppc64le ,$(SAFEHOSTARCH)),)
$(error build only supported on amd64, arm64 and ppc64le host currently)
endif

PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
TARGET_PLATFORM ?= $(HOSTOS)/$(TARGETARCH)
OUTPUT_DIR ?= $(PROJECT_DIR)/_output
BIN_OUTPUT_DIR ?= $(OUTPUT_DIR)/bin
GO_OUT_DIR ?= $(BIN_OUTPUT_DIR)/$(TARGET_PLATFORM)

$(GO_OUT_DIR):
	@mkdir -p $@

.PHONY: build
build: $(GO_OUT_DIR)
	@docker build --target bin --output $(GO_OUT_DIR) --platform $(TARGET_PLATFORM) .

.PHONY: image
image: $(TARGETARCH).image

%.image:
	@docker build --target img --platform linux/$* -t function .


.PHONY: lint
lint:
	@docker build . --target lint


.PHONY: test
test:
	@docker build . --target unit-test

