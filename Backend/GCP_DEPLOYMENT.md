# Deploying Sentra Pay to Google Cloud Platform (GCP)

This guide outlines the steps to deploy the Sentra Pay Backend (FastAPI + PostgreSQL) to GCP using Cloud Run and Cloud SQL.

## Prerequisites

1.  **GCP Account**: Create an account at [cloud.google.com](https://cloud.google.com).
2.  **gcloud CLI**: Install the Google Cloud SDK.
    - Run `gcloud init` to login and select your project.
3.  **Billing Enabled**: Ensure billing is enabled for your project.

## Step 1: Set up Environment

Enable the necessary Google Cloud APIs:

```bash
gcloud services enable artifactregistry.googleapis.com \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    sqladmin.googleapis.com
```

## Step 2: Create a Cloud SQL Instance (PostgreSQL)

1.  **Create the instance**:
    ```bash
    gcloud sql instances create sentra-db-instance \
        --database-version=POSTGRES_14 \
        --cpu=1 \
        --memory=4GiB \
        --region=us-central1
    ```
    *(Note: Adjust region and resources as needed. `db-f1-micro` is cheaper for testing but `db-custom-1-3840` is safer for production.)*

2.  **Set the password for the 'postgres' user**:
    ```bash
    gcloud sql users set-password postgres \
        --instance=sentra-db-instance \
        --password=YOUR_SECURE_PASSWORD
    ```

3.  **Create the database**:
    ```bash
    gcloud sql databases create fraud_detection --instance=sentra-db-instance
    ```

4.  **Get the Connection Name**:
    Run this to find the `connectionName` (e.g., `project-id:region:sentra-db-instance`):
    ```bash
    gcloud sql instances describe sentra-db-instance --format="value(connectionName)"
    ```

## Step 3: Build and Push Docker Image

1.  **Configure Docker Authentication**:
    ```bash
    gcloud auth configure-docker us-central1-docker.pkg.dev
    ```

2.  **Create an Artifact Registry Repository**:
    ```bash
    gcloud artifacts repositories create sentra-repo \
        --repository-format=docker \
        --location=us-central1 \
        --description="Sentra Pay Docker Repository"
    ```

3.  **Build the Image using Dockerfile.prod**:
    Replace `PROJECT_ID` with your actual GCP Project ID.
    ```bash
    docker build -t us-central1-docker.pkg.dev/PROJECT_ID/sentra-repo/sentra-backend:v1 -f Dockerfile.prod .
    ```

4.  **Push the Image**:
    ```bash
    docker push us-central1-docker.pkg.dev/PROJECT_ID/sentra-repo/sentra-backend:v1
    ```

## Step 4: Deploy to Cloud Run

Deploy the container to Cloud Run, connecting it to the Cloud SQL instance.

Replace:
- `PROJECT_ID`: Your GCP Project ID
- `INSTANCE_CONNECTION_NAME`: The connection name from Step 2.4
- `YOUR_SECURE_PASSWORD`: The password set in Step 2.2

```bash
gcloud run deploy sentra-backend \
    --image us-central1-docker.pkg.dev/PROJECT_ID/sentra-repo/sentra-backend:v1 \
    --region us-central1 \
    --platform managed \
    --allow-unauthenticated \
    --add-cloudsql-instances INSTANCE_CONNECTION_NAME \
    --set-env-vars "DATABASE_URL=postgresql+asyncpg://postgres:YOUR_SECURE_PASSWORD@/fraud_detection?host=/cloudsql/INSTANCE_CONNECTION_NAME" \
    --set-env-vars "SECRET_KEY=generate_a_strong_secret_key_here" \
    --set-env-vars "ENV=production"
```

**Important Note on DATABASE_URL**:
When running in Cloud Run with the Cloud SQL Auth Proxy sidecar (which is what `--add-cloudsql-instances` does), the host is a Unix socket at `/cloudsql/INSTANCE_CONNECTION_NAME`.
The format is:
`postgresql+asyncpg://USER:PASSWORD@/DB_NAME?host=/cloudsql/INSTANCE_CONNECTION_NAME`

## Step 5: Database Migration

After deployment, your database is empty. You need to run migrations.
You can run a "Job" in Cloud Run to execute the migration script.

1.  **Create a Job yaml (migrate-job.yaml)** or just run from your local machine if you whitelist your IP.
2.  **Easiest way for now**: Whitelist your local IP temporarily.
    ```bash
    gcloud sql instances patch sentra-db-instance --authorized-networks=YOUR_LOCAL_IP
    ```
    Then run Alembic locally pointing to the Cloud SQL public IP.
    *(Remember to remove your IP afterwards for security!)*

## Step 6: Frontend Deployment (Flutter)

1.  **Update API URL**: In your Flutter app (`lib/core/config/api_config.dart` or similar), change `baseUrl` to the URL provided by the Cloud Run deployment (e.g., `https://sentra-backend-xyz-uc.a.run.app`).

2.  **Build**:
    - **Android**: `flutter build apk --release`
    - **Web**: `flutter build web --release`

3.  **Deploy Web (Optional)**:
    If deploying the web dashboard, use Firebase Hosting:
    ```bash
    firebase init hosting
    firebase deploy
    ```

## Step 7: Redis (Optional)

If you need Redis for caching (recommended for production):
1.  Enable Memorystore for Redis API.
2.  Create a Redis instance.
3.  Add `REDIS_URL` to your Cloud Run environment variables.
4.  Note: Cloud Run requires a **Serverless VPC Access connector** to connect to Memorystore's private IP. This adds cost and complexity. For a simple MVP, you might skip Redis or use a managed Redis service with a public endpoint (like Redis Cloud).
