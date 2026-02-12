# Docker Setup for Sentra Pay Backend

This guide explains how to run the Sentra Pay Backend (FastAPI), PostgreSQL, and Redis using Docker. This setup ensures a consistent development environment without needing to install Python, Postgres, or Redis manually on your Windows machine.

## Prerequisites

- **Docker Desktop** installed and running.

## Running the Application

1. Open a terminal in the `Backend` directory:
   ```powershell
   cd c:\Users\harin\OneDrive\Desktop\DeepBlue\Backend
   ```

2. Start the services (Backend, Database, Redis):
   ```powershell
   docker-compose up --build
   ```
   - The `--build` flag ensures that the backend image is rebuilt with any code changes.
   - You will see logs from all three services.

3. The API will be available at: `http://localhost:8000`
   - **Swagger UI (Docs):** `http://localhost:8000/docs`

4. To stop the services, press `Ctrl+C` in the terminal, or run:
   ```powershell
   docker-compose down
   ```

## Services Overview

- **backend**: The FastAPI application. It is configured to reload automatically on code changes (`--reload` flag in Dockerfile), so you can edit code and see changes immediately.
- **postgres**: PostgreSQL 14 database. Data is persisted in a docker volume `postgres_data`.
  - Credentials:
    - User: `postgres`
    - Password: `sentra_secure_2026`
    - DB: `fraud_detection`
    - Port: `5432` (exposed to host)
- **redis**: Redis 7 cache.
  - Port: `6379` (exposed to host)

## Database Management

The `postgres` service is accessible on `localhost:5432`. You can connect to it using tools like **pgAdmin** or **DBeaver** with the credentials above.

## Troubleshooting

- **Port Conflicts**: Ensure ports `8000`, `5432`, and `6379` are not being used by other applications on your host machine.
- **Environment Variables**: The `docker-compose.yml` sets up environment variables for the backend to connect to `postgres` and `redis` containers. These override your local `.env` file when running in Docker.

## Running Tests in Docker

To run tests inside the Docker container:
```powershell
docker-compose exec backend pytest
```
