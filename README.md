# DeepSeek Codex Proxy

Systemd **system** service that keeps
[`@codeproxy/cli`](https://github.com/nicepkg/codeproxy) running in the
background, proxying OpenAI‑compatible requests to the DeepSeek API.

The package is **pinned locally** (`package.json` + `package-lock.json`) so
you're not dependent on the npm registry at runtime. Even if the package is
unpublished, your service keeps working against the installed version.

## Quick start

```bash
# 1. Set your API key
cp env.example env
# edit env → paste your real key

# 2. Install dependencies & the systemd service
./install.sh
```

The proxy listens at `http://localhost:50050` by default.

## Managing the service

| Action                   | Command                                      |
| ------------------------ | -------------------------------------------- |
| Status / health          | `systemctl status deepseek-proxy`            |
| Follow logs              | `journalctl -u deepseek-proxy -f`            |
| Stop                     | `sudo systemctl stop deepseek-proxy`         |
| Start                    | `sudo systemctl start deepseek-proxy`        |
| Restart                  | `sudo systemctl restart deepseek-proxy`      |
| Disable (no auto‑start)  | `sudo systemctl disable deepseek-proxy`      |
| Update to latest version | `npm update && sudo systemctl restart deepseek-proxy` |

## Error handling

- **`Restart=always`** – the service restarts automatically after any exit.
- **`RestartSec=5s`** – waits 5 seconds between restart attempts.
- **`StartLimitBurst=5` / `StartLimitIntervalSec=60s`** – gives up after 5
  crashes in a minute (prevents a crash‑loop from burning CPU).
- **`KillMode=mixed` + `KillSignal=SIGTERM` + `TimeoutStopSec=10s`** –
  graceful shutdown; SIGKILL sent only if the proxy is still alive after
  10 seconds.

To check why it last failed:

```bash
journalctl -u deepseek-proxy -n 50 --no-pager
```

## Files

```
.
├── env.example          # template (commit-safe)
├── env                  # API key (git‑ignored)
├── package.json         # pinned @codeproxy/cli dependency
├── package-lock.json    # exact version lock (commit this)
├── run.sh               # launch wrapper
├── install.sh           # npm install + enable systemd unit
├── deepseek-proxy.service
├── swap_codex_provider.sh  # toggle between DeepSeek and ChatGPT
├── .gitignore
└── README.md
```
