# Deployment Guide

Three deployable units. Each is deployed independently; only the backend and
ML service need to reach each other.

| Unit | Stack | Suggested host |
| --- | --- | --- |
| `backend/` | Node.js + Express | Render Web Service |
| `ml_service/` | FastAPI + HuggingFace | Render Web Service (or GPU host) |
| Flutter app | Flutter web / Android | Vercel (web), Play Store / APK |

> **Security:** never commit `.env` files. Set environment variables in your
> host's dashboard instead. Use strong, unique `JWT_SECRET` and `MONGODB_URI`
> values per environment. The current Firebase config is a placeholder; add
> real `google-services.json`/`GoogleService-Info.plist` and swap the stubs in
> `lib/config/firebase_options.dart` before enabling Google Sign-In.

## 1. MongoDB Atlas

1. Create a free cluster.
2. Under **Database Access** create a user (read/write).
3. Under **Network Access** allow the IP ranges of your hosts, or `0.0.0.0/0`
   (home testing only).
4. Copy the connection string. The collections and indexes are created
   automatically by Mongoose on first backend start.

## 2. ML service (FastAPI)

On Render (or any Python host):

1. Add a **Web Service**, root directory `ml_service`.
2. Build command:
   ```bash
   pip install -U pip && pip install -r requirements.txt
   ```
   > `requirements.txt` deliberately contains only the lightweight dev set.
   > For a production service add `torch`, `transformers` and
   > `opencv-python-headless` — the model download is several GB, so use a
   > GPU instance if available and mount persistent model storage.
3. Start command:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port $PORT
   ```
   (`PORT` is injected by Render.)
4. Environment variables:
   ```env
   MODEL_ID=dima806/deepfake_vs_real_image_detection
   MOCK_INFERENCE=0
   HF_TOKEN=            # only if the model is gated
   ```
5. Verify: `GET https://<ml-host>/health` → `{ "status": "ok", ... }`.

Environment is described in [`docs/API.md`](API.md#environment-variables-fastapi).

## 3. Backend (Node.js)

1. Add a **Web Service**, root directory `backend`.
2. Build command: `npm install`.
3. Start command: `node src/server.js`.
4. Environment variables:

   ```env
   PORT=                # injected by Render
   NODE_ENV=production
   MONGODB_URI=mongodb+srv://<user>:<pass>@<cluster>/<db>
   JWT_SECRET=<long random string at least 32 chars>
   FASTAPI_URL=https://<ml-host>    # public URL of the ML service
   MOCK_ML=0
   SENDER_EMAIL=chitravisionai@gmail.com
   SENDER_APP_PASSWORD=<gmail app password>
   ```

   > Gmail requires an [App Password](https://support.google.com/accounts/answer/185833)
   > (2-step verification enabled). Any SMTP provider works with `nodemailer`.
5. Verify: `GET https://<api-host>/api/health` →
   ```json
   { "status": "ok", "service": "chitravision-backend", "mlUrlConfigured": true }
   ```

## 4. Flutter app

### Web (Vercel)

```bash
flutter build web --dart-define=API_BASE_URL=https://<api-host>
```

Deploy the `build/web` directory to Vercel/Netlify/any static host.

### Android

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<api-host>
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

> The APK produced by `flutter build apk` is signed with the debug key and is
> for testing. For Play Store release configure a signing key in
> `android/app/build.gradle` and build an `appbundle`.

### iOS / macOS

`flutter build ios --release`; wire push + Google Sign-In with real Firebase
config before release.

## 5. Post-deployment checklist

- [ ] `/api/health` and ML `/health` respond `ok`
- [ ] `register` → `login` → `analyze` works end-to-end against production URLs
- [ ] Reset-password emails arrive (check Mail provider quota)
- [ ] Mongo indexes exist: `detections.userId_1_createdAt_-1`,
      `detections.userId_1_verdict_1`, `users.email_1`
- [ ] Real Firebase options swapped (no placeholder keys)
- [ ] Backups scheduled — see [`docs/BACKUP-RECOVERY.md`](BACKUP-RECOVERY.md)