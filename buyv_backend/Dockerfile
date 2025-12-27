# Use official Python runtime as a parent image
FROM python:3.11-slim

# Set environment variables
# PYTHONDONTWRITEBYTECODE 1: Prevents Python from writing .pyc files
# PYTHONUNBUFFERED 1: Ensures container logging is output straight to the terminal
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /app

# Install system dependencies (gcc might be needed for some python packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project binaries
COPY . .

# Expose port (Railway will set PORT env var, but this is good documentation)
EXPOSE 8000

# Run the application
# Railway sets the $PORT variable, so we must bind to it.
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
