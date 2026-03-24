#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# init-vault.sh — Premier démarrage : init + unseal + login
# Usage : bash init-vault.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

VAULT_ADDR="http://127.0.0.1:8200"
KEYS_FILE="./vault-init-keys.json"   # ⚠️  à stocker en lieu sûr / chiffrer !
VAULT="docker exec -e VAULT_ADDR=${VAULT_ADDR} vault vault"

export VAULT_ADDR

echo "⏳  Attente de Vault..."
# /v1/sys/health retourne 501 (non-init) ou 503 (sealed) — on ignore le code HTTP
until curl -s -o /dev/null "${VAULT_ADDR}/v1/sys/health"; do
  sleep 2
done

# vault status -format=json sort code 0 (unsealed), 2 (sealed), 1 (error)
VAULT_STATUS=$(${VAULT} status -format=json 2>/dev/null || true)

# ── Initialisation ─────────────────────────────────────────────────────────────
INITIALIZED=$(echo "${VAULT_STATUS}" | jq -r '.initialized // false' 2>/dev/null || echo "false")
if [[ "${INITIALIZED}" != "true" ]]; then
  echo "🔑  Initialisation de Vault..."
  ${VAULT} operator init \
    -key-shares=5 \
    -key-threshold=3 \
    -format=json > "${KEYS_FILE}"
  echo "✅  Clés sauvegardées dans ${KEYS_FILE}"
  VAULT_STATUS=$(${VAULT} status -format=json 2>/dev/null || true)
else
  echo "ℹ️   Vault déjà initialisé."
fi

# ── Unseal ─────────────────────────────────────────────────────────────────────
SEALED=$(echo "${VAULT_STATUS}" | jq -r '.sealed // true' 2>/dev/null || echo "true")
if [[ "${SEALED}" == "true" ]]; then
  echo "🔓  Unseal en cours (3 clés requises)..."
  for i in 0 1 2; do
    KEY=$(jq -r ".unseal_keys_b64[${i}]" "${KEYS_FILE}")
    ${VAULT} operator unseal "${KEY}"
  done
  echo "✅  Vault unsealed."
fi

# ── Login root (première fois seulement) ───────────────────────────────────────
ROOT_TOKEN=$(jq -r '.root_token' "${KEYS_FILE}" 2>/dev/null || echo "")
if [[ -n "${ROOT_TOKEN}" ]]; then
  echo "🔐  Login avec le token root..."
  ${VAULT} login "${ROOT_TOKEN}"
  echo ""
  echo "⚠️   IMPORTANT : sauvegarde ${KEYS_FILE} dans un endroit sûr"
  echo "     puis supprime-le ou chiffre-le (ex: gpg -c ${KEYS_FILE})"
fi

echo ""
echo "🏁  Vault prêt sur ${VAULT_ADDR}"
echo "    UI → ${VAULT_ADDR}/ui"
