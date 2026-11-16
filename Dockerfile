# Multi-stage build for hosting GTOpen (CPU-only; no CUDA/gpu feature) on
# Railway or any container host. Local desktop use stays on GTOpen.cmd/start.sh.

FROM rust:1-bookworm AS builder
WORKDIR /build

COPY Cargo.toml Cargo.lock ./
COPY crates/solver crates/solver
COPY crates/server crates/server
RUN cargo build --release -p server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /build/target/release/gto-server /app/gto-server
COPY web /app/web
COPY docs /app/docs
COPY cache /app/cache

# saves/ is expected to be a mounted Railway volume so solved games and
# profiles persist across deploys; create it so a fresh volume starts
# writable even before anything is uploaded.
RUN mkdir -p /app/saves

ENV GTOPEN_HOST=0.0.0.0
EXPOSE 3737
CMD ["/app/gto-server"]
