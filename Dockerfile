# Multi-stage build for Python Flask application
FROM python:3.11-slim as base

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Create and set the working directory
WORKDIR /app

# Install system dependencies for python-magic
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libmagic1 \
        file && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY src/ ./src/

# Create uploads directory
RUN mkdir -p /app/uploads && \
    chmod 755 /app/uploads

# Create a non-root user
RUN groupadd -r appuser && \
    useradd -r -g appuser -d /app -s /sbin/nologin appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5001/health')" || exit 1

# Set the working directory to src for the application
WORKDIR /app/src

# Run the application
CMD ["python", "app.py"]