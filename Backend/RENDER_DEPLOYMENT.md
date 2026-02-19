[render.com](https://render.com) is often **much easier** than GCP for small-to-medium projects because it handles the database, Redis, and SSL certificates automatically.

Here is how to deploy Sentra Pay on Render:

## 1. Create a `render.yaml` (Infrastructure as Code)

Create a file named `render.yaml` in the root of your `Backend` folder. This tells Render exactly what to build.

```yaml
services:
  # 1. The FastAPI Backend
  - type: web
    name: sentra-pay-backend
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn app.main:app --host 0.0.0.0 --port 10000
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: sentra-db
          property: connectionString
      - key: REDIS_URL
        fromService:
          type: redis
          name: sentra-redis
          property: connectionString
      - key: SECRET_KEY
        generateValue: true
      - key: ENV
        value: production

databases:
  # 2. The PostgreSQL Database
  - name: sentra-db
    databaseName: sentra_pay
    user: sentra_user
    plan: free # Free tier available!

services:
  # 3. Redis Cache (Optional, but recommended)
  - type: redis
    name: sentra-redis
    ipAllowList: [] # Only allow internal connections
    plan: free # Free tier available!
```

## 2. Push Your Code to GitHub/GitLab
Render deploys directly from your Git repository.
1.  Initialize git if you haven't: `git init`
2.  Commit your code: `git add . && git commit -m "Deploy to Render"`
3.  Push to a repo: `git push origin main`

## 3. Connect Render
1.  Go to [dashboard.render.com](https://dashboard.render.com)
2.  Click **"New +"** -> **"Blueprint"**
3.  Connect your GitHub repository.
4.  Render will automatically detect the `render.yaml` file and ask you to approve the resources (Service + Database + Redis).
5.  Click **"Apply"**.

## 4. That's it!
Render will:
-   Build your Python app.
-   Spin up a PostgreSQL database.
-   Spin up a Redis instance.
-   Connect them all together using the environment variables defined in the YAML.
-   Give you a URL like `https://sentra-pay-backend.onrender.com`.

## 5. Post-Deployment Steps
Once deployed, your database is empty. You need to run migrations.
1.  Go to the Render Dashboard -> `sentra-pay-backend` -> **Shell**.
2.  Run the migration command:
    ```bash
    alembic upgrade head
    ```
3.  (Optional) Create a demo user:
    ```python
    python -c "from app.database.connection import SessionLocal; from app.models import User; db = SessionLocal(); ..."
    ```

## Comparison: Render vs GCP
| Feature | Render | Google Cloud |
| :--- | :--- | :--- |
| **Ease of Use** | ⭐⭐⭐⭐⭐ (Very Easy) | ⭐⭐⭐ (Complex) |
| **Setup Time** | ~5 Minutes | ~30-60 Minutes |
| **Free Tier** | ✅ Yes (DB + Service) | ✅ Yes (Always Free limits) |
| **Scalability** | Good for Startups | Infinite (Enterprise) |
| **Database** | Managed PostgreSQL | Cloud SQL (Managed) |

**Recommendation:** For a student project, hackathon, or MVP, **Render is significantly better**. It removes all the DevOps headaches.
