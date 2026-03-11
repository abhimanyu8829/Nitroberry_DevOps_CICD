Push to main
      │
      ▼
┌─────────────────┐
│   validate      │  ← runs ONCE (single job)
│  (Lint & Test)  │
└────────┬────────┘
         │
    ✅ success
         │
         ▼
┌─────────────────────────────────────────────────┐
│              build-scan-push                    │
│                                                 │
│  [api]      [cron]      [dev]      [prod]       │
│                                                 │
│  build  →  build  →   build  →   build          │
│  scan   →  scan   →   scan   →   scan           │
│  push   →  push   →   push   →   push           │
│                                                 │
│  (all 4 run in parallel at the same time)       │
└─────────────────────────────────────────────────┘
