FROM --platform=${BUILDPLATFORM} golang:1.20.5-alpine AS base

WORKDIR /src
ENV CGO_ENABLED=0
COPY go.* .
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

FROM base AS build-stage
ARG TARGETOS
ARG TARGETARCH
RUN --mount=readonly=false,target=. \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=${TARGETOS} GOARCH=${TARGETARCH}  go run -tags generate sigs.k8s.io/controller-tools/cmd/controller-gen \
    paths=./input/v1beta1 object crd:crdVersions=v1 output:artifacts:config=/out/package/input


RUN --mount=target=. \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=${TARGETOS} GOARCH=${TARGETARCH}  go build -o /out/function .


FROM base AS unit-test
RUN --mount=target=. \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go test -cover ./...

FROM golangci/golangci-lint:v1.54.2 AS lint-base

FROM base AS lint
RUN --mount=target=. \
    --mount=from=lint-base,src=/usr/bin/golangci-lint,target=/usr/bin/golangci-lint \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/.cache/golangci-lint \
    golangci-lint run --timeout 10m0s ./...

FROM scratch AS bin-unix
COPY --from=build-stage /out/function /

FROM bin-unix AS bin-linux
FROM bin-unix AS bin-darwin

FROM scratch AS bin-windows
COPY --from=build-stage /out/function /function.exe

FROM bin-${TARGETOS} as bin

FROM debian:12.1-slim as package-stage

# TODO(negz): Use a proper Crossplane package building tool. We're abusing the
# fact that this image won't have an io.crossplane.pkg: base annotation. This
# means Crossplane package manager will pull this entire ~100MB image, which
# also happens to contain a valid Function runtime.
# https://github.com/crossplane/crossplane/blob/v1.13.2/contributing/specifications/xpkg.md
WORKDIR /package
COPY --from=build-stage /out/package/ ./
COPY package/crossplane.yaml ./

RUN cat crossplane.yaml > /package.yaml
RUN cat input/*.yaml >> /package.yaml

FROM gcr.io/distroless/base-debian11 AS img

WORKDIR /

COPY --from=bin /function /function
COPY --from=package-stage /package.yaml /package.yaml

EXPOSE 9443

USER nonroot:nonroot

ENTRYPOINT ["/function"]