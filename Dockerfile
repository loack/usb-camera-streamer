FROM alpine:3.18

# Install system dependencies including build tools for ustreamer
RUN apk add --no-cache \
    python3 \
    py3-pip \
    python3-dev \
    v4l-utils \
    bash \
    git \
    make \
    gcc \
    g++ \
    musl-dev \
    linux-headers \
    libjpeg-turbo-dev \
    libevdev-dev \
    libevent-dev \
    libbsd-dev \
    && rm -rf /var/cache/apk/*

# Build and install ustreamer from source
RUN git clone https://github.com/pikvm/ustreamer.git /tmp/ustreamer \
    && cd /tmp/ustreamer \
    && make -j4 \
    && make install \
    && cd / \
    && rm -rf /tmp/ustreamer

# Set up Python environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy requirements first for better Docker layer caching
COPY requirements.txt .

# Install Python dependencies (keeping build tools for compilation)
RUN pip install --no-cache-dir -r requirements.txt

# Remove build dependencies to reduce image size (after Python packages are installed)
RUN apk del git make gcc g++ musl-dev linux-headers

# Copy application files
COPY app.py .
COPY templates/ templates/

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN chown -R appuser:appgroup /app

# Expose ports
EXPOSE 5000 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import requests; requests.get('http://localhost:5000/api/stream/status')" || exit 1

# Switch to non-root user
USER appuser

# Run the application
CMD ["python3", "app.py"]
