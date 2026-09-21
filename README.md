# ChitraVision AI — Deepfake & AI-Generated Content Detection Platform

Detect AI-generated images, deepfake faces and manipulated videos with a
Flutter app, a Node.js REST backend and a HuggingFace-powered FastAPI ML
service.

```
Flutter App → Node.js Express (REST + JWT) → FastAPI ML Service → HuggingFace Model
                                                        ↓            ↓
                                                   Prediction    MongoDB (Atlas)
                                                                        ↓
Flutter Result Screen ←────────────────────── Saved Detection ←──────────┘
```

## Architecture

| Layer | Tech | Location |
| --- | --- | --- |
| Mobile / Web app | Flutter + Dart | `lib/` |
| Backend API | Node.js + Express + Mongoose | `backend/` |
| ML service | Python + FastAPI + HuggingFace Transformers + OpenCV | `ml_service/` |
| Database | MongoDB Atlas | remote |
| Deploy | Render (backend + ML), Vercel (Flutter web) | — |

Detection flow:

1. Flutter uploads media to `POST /api/detections/analyze` (multipart, JWT).
2. Node.js validates the file (type + size) and forwards it to FastAPI.
3. FastAPI runs the `dima806/deepfake_vs_real_image_detection` model
   (per-frame for videos via OpenCV).
4. The prediction + confidence is saved to MongoDB and returned to the app.

## Repository layout

```
backend/      Express API, Mongoose models, middleware, integration tests
ml_service/   FastAPI app, model wrapper, video processing, pytest suite
lib/          Flutter application (screens, services, widgets)
docs/         API, deployment and backup/recovery documentation
```

## Technology stack

- **App:** Flutter (Material 3), `http`, `file_picker`, `image`, `shared_preferences`, `flutter_dotenv`
- **Backend:** Express 4, Mongoose 8, JWT (`jsonwebtoken`), `bcryptjs`, `multer`, `nodemailer`, `cors`, `dotenv`
- **ML:** FastAPI, Uvicorn, Pillow, `torch`, `transformers`,
  `opencv-python-headless`; model `dima806/deepfake_vs_real_image_detection`
- **DB:** MongoDB Atlas

## Setup

Prerequisites: Flutter 3.x, Node 18+, Python 3.10+, a MongoDB Atlas cluster,
and (for real inference) a HuggingFace account with access to the model.

### 1. Clone & prepare each component

```bash
# Copy env templates (never commit real .env files)
cp .env.example .env                    # Flutter app config
cp backend/.env.example backend/.env    # Backend secrets & URLs
cp ml_service/.env.example ml_service/.env
```

### 2. Environment variables

#### `backend/.env`

```env
PORT=4000
NODE_ENV=development
MONGODB_URI=mongodb+srv://USER:PASSWORD@HOST/db
JWT_SECRET=replace-me-with-a-long-random-string
FASTAPI_URL=http://localhost:8000        # ML service URL
MOCK_ML=0                                # 1 = skip ML service in dev/tests
SENDER_EMAIL=you@gmail.com
SENDER_APP_PASSWORD=your-gmail-app-password
```

#### `ml_service/.env`

```env
MODEL_ID=dima806/deepfake_vs_real_image_detection
MOCK_INFERENCE=0     # 1 = deterministic mock (no model download)
HF_TOKEN=
```

#### `.env` (Flutter)

```env
API_BASE_URL=http://localhost:4000
```

The Flutter base URL can also be overridden per build:
`flutter run --dart-define=API_BASE_URL=https://your-backend.com`.

### 3. Install dependencies

```bash
# Backend
cd backend && npm install

# ML service (lightweight dev set — no torch)
cd ml_service && python -m venv .venv
.venv/Scripts/pip install -U pip fastapi uvicorn python-multipart pillow python-dotenv pytest httpx
# For real inference additionally:
#   .venv/Scripts/pip install torch transformers opencv-python-headless

# Flutter
cd .. && flutter pub get
```

### 4. Run everything

```bash
# 1. ML service (recommended: MOCK_INFERENCE=1 on first run — no model download)
cd ml_service && .venv/Scripts/uvicorn app.main:app --port 8000

# 2. Backend
cd backend && npm run dev

# 3. Flutter app (web)
flutter run -d chrome
# or a release build:
flutter build web
flutter build apk --release   # Android APK
```

> In mock mode (`MOCK_INFERENCE=1` / `MOCK_ML=1`) predictions are
> deterministic, so you can develop and test the full pipeline without
> downloading the multi-GB model.

### 5. MongoDB setup

1. Create a cluster on [MongoDB Atlas](https://www.mongodb.com/atlas).
2. Create a database user and copy the connection string into `backend/.env`.
3. With the backend running the collections are created automatically.
4. Relevant collections: `users`, `detections`, `passwordresets`.

Indexes (auto-created by Mongoose):

- `detections`: `{ userId: 1, createdAt: -1 }`, `{ userId: 1, verdict: 1 }`
- `users`: `{ email: 1 }` (unique)
- `passwordresets`: `{ email: 1, used: 1, createdAt: -1 }`

## Administration

Giving a user admin rights (safe way):

```bash
# In mongosh / Compass on the `users` collection:
db.users.updateOne({ email: "you@example.com" }, { $set: { isAdmin: true } })
```

## Tests

```bash
# Backend integration suite (needs MONGODB_URI in backend/.env)
cd backend && npm test

# ML service API tests (mock mode — fast, no model weights)
cd ml_service && MOCK_INFERENCE=1 .venv/Scripts/pytest tests -v

# Flutter static analysis
flutter analyze
```

## API documentation

See [`docs/API.md`](docs/API.md) for the complete reference. The FastAPI
service also exposes Swagger at `/docs` and its raw spec at `/openapi.json`.

## Deployment

See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) and
[`docs/BACKUP-RECOVERY.md`](docs/BACKUP-RECOVERY.md).

## Git workflow

This repository uses a simple branching model:

- `main` — stable, tagged releases
- `develop` — integration branch for ongoing work
- `feature/*` — one branch per feature (e.g. `feature/security`)