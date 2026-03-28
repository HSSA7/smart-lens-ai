# Smart Lens AI

An AI-powered image recognition app. Point your phone at any object and get an instant AI-generated label.

## Architecture

```
Flutter App (client_app)
      │
      ▼
Node.js Orchestrator (orchestrator/) — port 3000
      │                   │
      ▼                   ▼
Python AI Engine     PostgreSQL DB
(ai-engine/) p.8000  (via Docker)
```

---

## Prerequisites

Install these before running anything:

| Tool | Purpose | Download |
|------|---------|----------|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Runs the PostgreSQL database | docker.com |
| [Node.js v18+](https://nodejs.org/) | Runs the orchestrator | nodejs.org |
| [Python 3.10+](https://www.python.org/downloads/) | Runs the AI engine | python.org |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | Runs the mobile app | flutter.dev |

---

## Setup & Run (3 terminals required)

### Step 1 — Start the Database

```bash
docker compose up -d
```

This starts a PostgreSQL container. Only needs to run once (data persists).

---

### Step 2 — Start the AI Engine

```bash
cd ai-engine
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Runs at `http://localhost:8000`

---

### Step 3 — Start the Orchestrator

```bash
cd orchestrator
npm install
cp .env.example .env            # creates your local config file
npx prisma generate
npx prisma migrate deploy
node server.js
```

Runs at `http://localhost:3000`

---

### Step 4 — Run the Flutter App

```bash
cd client_app
flutter pub get
flutter run
```

Pick your target device (Chrome, Android emulator, iOS simulator, etc.) when prompted.

---

## Environment Variables

The orchestrator needs a `.env` file (created in Step 3 above from `.env.example`).
The default values match the Docker Compose database config — no changes needed for local dev.

```
DATABASE_URL="postgresql://admin:secretpassword@localhost:5432/smartlens?schema=public"
```

---

## Stopping Everything

```bash
docker compose down       # stops the database
# Ctrl+C in the other two terminals
```
