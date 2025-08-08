# Multi-stage build for vlmcsd
# Build stage
FROM alpine:3.22 AS builder

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev \
    make \
    linux-headers

# Set working directory
WORKDIR /build

# Copy source code
COPY . .

# Build vlmcsd with optimized flags for container deployment
RUN make \
    CC=gcc \
    CFLAGS="-O2 -s" \
    PROGRAM_NAME=/tmp/vlmcsd \
    CLIENT_NAME=/tmp/vlmcs

# Runtime stage
FROM alpine:3.22

# Add metadata
LABEL maintainer="vlmcsd" \
      description="KMS server emulator" \
      version="latest"

# Install runtime dependencies (none needed for static build)
RUN apk add --no-cache ca-certificates

# Create non-root user for security
RUN adduser -D -s /bin/sh vlmcsd

# Copy binaries from builder stage
COPY --from=builder /tmp/vlmcsd /usr/bin/vlmcsd
COPY --from=builder /tmp/vlmcs /usr/bin/vlmcs

# Copy configuration files
COPY etc/vlmcsd.ini /etc/vlmcsd.ini

# Set permissions
RUN chmod +x /usr/bin/vlmcsd /usr/bin/vlmcs && \
    chown root:root /usr/bin/vlmcsd /usr/bin/vlmcs

# Expose KMS port
EXPOSE 1688/tcp

# Switch to non-root user
USER vlmcsd

# Set default command
CMD ["/usr/bin/vlmcsd", "-D", "-e"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/bin/vlmcs -l 3 localhost || exit 1