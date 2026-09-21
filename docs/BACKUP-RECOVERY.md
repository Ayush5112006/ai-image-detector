# Backup & Recovery

Procedures for backing up the platform's data and recovering it in case of
loss, plus the secrets-restore flow.

## What to back up

| Data | Where it lives | Frequency (suggested) |
| --- | --- | --- |
| Users, detections, password-reset records | MongoDB Atlas | nightly |
| Backend & ML environment variables / secrets | Host dashboards + local `.env` files | on change |
| Source code | Git repository + remote | every commit |
| Flutter build artifacts | CI / release channel | per release |
| ML model cache | HuggingFace cache on the ML host | rarely (re-downloadable) |

> `.env` files contain secrets. Store a copy in a password manager or an
> encrypted vault **once** — never in Git.

## 1. MongoDB backups

### Atlas automated backups

1. Atlas → your cluster → **Backup**.
2. Enable **Cloud Backup** (M0 free tier does not support it; a scheduled
   `mongodump` below is the free alternative).
3. Set a schedule (daily) and a retention policy (e.g. 7 days).
4. Test a restore into a scratch cluster at least once a month.

### Free / self-hosted: `mongodump`

```bash
# Needs mongodump (install the MongoDB Database Tools)
mongodump --uri "mongodb+srv://USER:PASS@CLUSTER/dbname" \
  --out ./backups/$(date +%Y-%m-%d)

# Restore (creates/overwrites collections in the target DB)
mongorestore --uri "mongodb+srv://USER:PASS@CLUSTER/restored-db" \
  ./backups/2026-09-21/
```

Tip for Windows: put it on a scheduled task; for servers use cron/systemd.

### Point-in-time recovery

Atlas **PITR** (paid tiers) lets you restore to a timestamp. Enable it in the
Backup settings if you need "undo" granularity for bad updates or deletions.

## 2. Environment & secrets restore

If a host or local machine is lost you need:

- `MONGODB_URI` (Atlas cluster + DB user credentials)
- `JWT_SECRET` (re-issueing a new one **logs out every user** — user-facing impact)
- `SENDER_EMAIL` / `SENDER_APP_PASSWORD` (mail provider app password)
- `FASTAPI_URL`, `HF_TOKEN`, `MODEL_ID`

Keep these in a password manager, encrypted vault, or a `1Password/SOPS`
secrets file that is *not* committed. The `.env.example` files (`backend/`,
`ml_service/`, root) document exactly which variables exist.

## 3. Code repository

- Push to a remote Git host (`git push`); keep `origin` configured.
- Use the `develop` branch for integration work; tag releases on `main`
  (`git tag v1.0.0`) so you can always roll back to a known-good revision.

## 4. Recovery drills

### Full restore

1. Restore the MongoDB dump into a fresh Atlas DB (or re-point `MONGODB_URI`).
2. Re-deploy backend + ML from Git (`npm install`, pip install, env vars).
3. Point the app's `API_BASE_URL` at the recovered backend.
4. Verify with the checklist in [`docs/DEPLOYMENT.md`](DEPLOYMENT.md#5-post-deployment-checklist).

### Missing ML model

The model (`dima806/deepfake_vs_real_image_detection`) is re-downloaded
automatically on first request. If the HF host is slow, pre-warm by hitting
`/health` or disable/longen the MPI:

- Increase backend request timeouts (`ML_TIMEOUT`).
- Pre-fetch the model at deploy time (startup) instead of on first request.

## 5. Incident runbook (quick)

| Symptom | First checks | Recovery |
| --- | --- | --- |
| Login 401 for everyone | `JWT_SECRET` changed? | Restore old secret; or accept re-login |
| `503 ML_SERVICE_UNAVAILABLE` | ML host up? `FASTAPI_URL` correct? | Restart ML service; set `MOCK_ML=1` as a temporary fallback |
| Mongo connection errors | Atlas IP allow-list, credentials, cluster state | Restore creds; extend network access |
| Verification emails fail | App password revoked / quota exceeded | Refresh Gmail app password; check `send-otp` logs |
| Data loss | Last backup time | `mongorestore` from newest dump; activate PITR if enabled |

## Logging

Custom backends log JSON lines (with `requestId` + timing) — see
`backend/src/utils/logger.js` and `ml_service/app/logger.py`. Ship these to an
aggregator (e.g. Render logs, Logtail, CloudWatch) to support the runbook
above. Logs must never contain passwords, tokens, JWT secrets or OTPs.