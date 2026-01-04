FROM ubuntu:22.04

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    systemd \
    iproute2 \
    iptables \
    net-tools \
    dbus \
    supervisor \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18.x (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs


# Install GenieACS
RUN npm install -g genieacs@1.2.13

# Create genieacs user and directories
RUN useradd --system --no-create-home --user-group genieacs \
    && mkdir -p /opt/genieacs/ext \
    && mkdir -p /var/log/genieacs \
    && chown -R genieacs:genieacs /opt/genieacs \
    && chown -R genieacs:genieacs /var/log/genieacs

# Create data directories
RUN mkdir -p /data/logs /var/log/supervisor \
    && chown -R genieacs:genieacs /data/logs

# Copy configuration files
COPY config/ /opt/genieacs/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set proper permissions (if genieacs.env exists)
RUN if [ -f /opt/genieacs/genieacs.env ]; then \
        chown genieacs:genieacs /opt/genieacs/genieacs.env \
        && chmod 600 /opt/genieacs/genieacs.env; \
    fi

# Expose ports
EXPOSE 7547 7557 7567 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000 || exit 1

# Start supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
