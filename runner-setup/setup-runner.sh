#!/usr/bin/env bash
# Felix Payments — GitHub Actions Self-Hosted Runner Setup
# Targets: 10.10.100.26 (DevOps/CI) and 10.10.100.38 (Dev server)
# Run this script on each CI server as root or a user with Docker access.
#
# Usage:
#   ./setup-runner.sh <RUNNER_NAME> <GITHUB_ORG_TOKEN> [RUNNER_LABELS]
#
# Example:
#   ./setup-runner.sh fps-ci-1 ghp_xxxx "fps-ci,qt65,skb"
#   ./setup-runner.sh fps-ci-2 ghp_xxxx "fps-ci,qt65,skb"
#
# Token: Create at https://github.com/organizations/felixpsystems/settings/actions/runners/new
# Required scopes: admin:org

set -euo pipefail

RUNNER_NAME="${1:?Usage: $0 <runner-name> <token> [labels]}"
GITHUB_TOKEN="${2:?Usage: $0 <runner-name> <token> [labels]}"
RUNNER_LABELS="${3:-fps-ci,qt65,skb}"
GITHUB_ORG="felixpsystems"
RUNNER_VERSION="2.321.0"
PRIVATE_REGISTRY="10.10.100.86"

echo "=== Felix Payments — GitHub Actions Runner Setup ==="
echo "Runner name  : ${RUNNER_NAME}"
echo "Org          : ${GITHUB_ORG}"
echo "Labels       : ${RUNNER_LABELS}"
echo ""

# ── 1. System dependencies ──────────────────────────────────────────────────
echo "[1/6] Installing system dependencies..."
apt-get update -qq
apt-get install -y -qq curl jq git docker.io docker-compose libicu-dev

# Add current user to docker group
usermod -aG docker "${USER}" || true

# ── 2. Create runner user ────────────────────────────────────────────────────
echo "[2/6] Creating fps-runner user..."
id fps-runner &>/dev/null || useradd -m -s /bin/bash fps-runner
usermod -aG docker fps-runner

# ── 3. Download GitHub Actions runner ───────────────────────────────────────
echo "[3/6] Downloading GitHub Actions runner v${RUNNER_VERSION}..."
RUNNER_DIR="/home/fps-runner/actions-runner-${RUNNER_NAME}"
mkdir -p "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

RUNNER_TAR="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
if [ ! -f "${RUNNER_TAR}" ]; then
  curl -fsSL \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_TAR}" \
    -o "${RUNNER_TAR}"
fi
tar xzf "${RUNNER_TAR}" --overwrite
chown -R fps-runner:fps-runner "${RUNNER_DIR}"

# ── 4. Configure runner ──────────────────────────────────────────────────────
echo "[4/6] Configuring runner..."
sudo -u fps-runner ./config.sh \
  --url "https://github.com/${GITHUB_ORG}" \
  --token "${GITHUB_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --work "_work" \
  --replace \
  --unattended

# ── 5. Install as systemd service ───────────────────────────────────────────
echo "[5/6] Installing systemd service..."
./svc.sh install fps-runner
./svc.sh start

systemctl enable "actions.runner.${GITHUB_ORG}.${RUNNER_NAME}" || true

# ── 6. Configure Docker login for private registry ──────────────────────────
echo "[6/6] Setting up private registry access..."
# Registry credentials are injected via GitHub Secrets at runtime.
# Pre-configure insecure registry if using HTTP (private network):
DOCKER_DAEMON_FILE="/etc/docker/daemon.json"
if [ ! -f "${DOCKER_DAEMON_FILE}" ]; then
  cat > "${DOCKER_DAEMON_FILE}" <<EOF
{
  "insecure-registries": [
    "${PRIVATE_REGISTRY}:5000",
    "${PRIVATE_REGISTRY}:5001",
    "${PRIVATE_REGISTRY}:5002",
    "${PRIVATE_REGISTRY}:5003",
    "${PRIVATE_REGISTRY}:5004",
    "${PRIVATE_REGISTRY}:5005",
    "${PRIVATE_REGISTRY}:5006",
    "${PRIVATE_REGISTRY}:5007",
    "${PRIVATE_REGISTRY}:5008",
    "${PRIVATE_REGISTRY}:5009",
    "${PRIVATE_REGISTRY}:5010",
    "${PRIVATE_REGISTRY}:5011"
  ]
}
EOF
  systemctl restart docker
  echo "Docker daemon reconfigured for private registry: ${PRIVATE_REGISTRY}"
else
  echo "Docker daemon.json already exists — add insecure-registries manually if needed."
fi

echo ""
echo "=== ✅ Runner setup complete ==="
echo "Runner '${RUNNER_NAME}' is registered and running."
echo "Check status: systemctl status actions.runner.${GITHUB_ORG}.${RUNNER_NAME}"
echo ""
echo "=== Next Steps ==="
echo "1. Build the fps-ci-base Docker image:"
echo "   cd runner-setup && docker build -t ${PRIVATE_REGISTRY}:5011/fps-ci-base:qt65 -f Dockerfile.fps-ci-base ."
echo "   docker push ${PRIVATE_REGISTRY}:5011/fps-ci-base:qt65"
echo ""
echo "2. Add org-level GitHub Secrets at:"
echo "   https://github.com/organizations/felixpsystems/settings/secrets/actions"
echo "   See: runner-setup/SECRETS.md for the full list"
