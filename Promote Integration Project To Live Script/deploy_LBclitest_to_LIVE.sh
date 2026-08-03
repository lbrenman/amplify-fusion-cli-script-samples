#!/usr/bin/env bash
#
# Fusion deployment script to run after versioning a project in DESIGN to deploy it to LIVE
#
# It is for a Fusion project: LBclitest, with a single flow: flow1, and a single data plane: Shared Data Plane
#
# Requires three environment variables set OUTSIDE this script:
#   VER       e.g. V66
#   USERNAME  e.g. leor.brenman@gmail.com
#   PASSWORD  your password
#
# Optional environment variables (BOTH must be set to take effect):
#   CONNECTION_USERNAME
#   CONNECTION_PASSWORD
#   When both are set, the script imports a connection override
#   (http_server_override.json) in LIVE, just before re-enabling the event.
#   If either is unset/empty, the import step is skipped.
#
# Example:
#   export VER=V66
#   export USERNAME=leor.brenman@gmail.com
#   export PASSWORD='...'
#   # Optional — set BOTH to import the connection override:
#   export CONNECTION_USERNAME='...'
#   export CONNECTION_PASSWORD='...'
#   ./deploy_LBclitest_to_LIVE.sh
#
# See the bottom of this file for a sample successful run.
#
# -e            exit immediately if any command fails
# -u            treat use of an unset variable as an error
# -o pipefail   a pipeline fails if any element fails
set -euo pipefail

# --- Configuration --------------------------------------------------------
# The `fusion` alias from your interactive shell is NOT available inside a
# script, so we define the command here as an array. Override it if needed:
#   export FUSION_JAR=/path/to/fusion-cli-1.0.0-runner.jar
FUSION_JAR="${FUSION_JAR:-/Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar}"
FUSION=(java -jar "${FUSION_JAR}")

URL="https://axway-appc-se.sandbox.fusion.services.axway.com/"
PROJECT="LBclitest"
FLOW="flow1"
DATA_PLANE="Shared Data Plane"

# --- Validate required environment variables ------------------------------
: "${VER:?Environment variable VER is not set (e.g. export VER=V66)}"
: "${USERNAME:?Environment variable USERNAME is not set}"
: "${PASSWORD:?Environment variable PASSWORD is not set}"

# Derived names — braces make the boundary explicit when concatenating,
# and the surrounding double quotes keep everything as a single argument.
DEPLOYMENT_NAME="${PROJECT}_dj_${VER}"
PROJECT_VERSION="${PROJECT},${VER}"

# --- Helper: print a step banner ------------------------------------------
step() {
  echo ""
  echo "==> $1"
}

# --- Helper: print the command (password masked), then run it -------------
run() {
  local display=() arg
  for arg in "$@"; do
    if [[ -n "${PASSWORD:-}" && "${arg}" == "${PASSWORD}" ]]; then
      arg="********"
    fi
    # Quote args that contain spaces (or are empty) so the printed line is
    # copy-pasteable and readable, e.g. "Shared Data Plane".
    if [[ "${arg}" == *" "* || -z "${arg}" ]]; then
      display+=("\"${arg}\"")
    else
      display+=("${arg}")
    fi
  done
  echo "    \$ ${display[*]}"
  "$@"
}

# --- Deployment steps -----------------------------------------------------

step "Logging in as ${USERNAME}"
run "${FUSION[@]}" auth login -u "${USERNAME}" -p "${PASSWORD}" --url "${URL}"

step "Deactivating project event (${PROJECT}/${FLOW})"
run "${FUSION[@]}" project event disable -n "${PROJECT}" -in "${FLOW}" -cn "${DATA_PLANE}"

step "Creating deployment job: ${DEPLOYMENT_NAME}"
run "${FUSION[@]}" deployment create \
  -n "${DEPLOYMENT_NAME}" \
  -d "${DEPLOYMENT_NAME}" \
  -pv "${PROJECT_VERSION}"

step "Switching to LIVE"
run "${FUSION[@]}" environment switch -n LIVE

step "Deactivating project event in LIVE"
run "${FUSION[@]}" project event disable -n "${PROJECT}" -in "${FLOW}" -cn "${DATA_PLANE}"

step "Switching to DESIGN"
run "${FUSION[@]}" environment switch -n DESIGN

step "Running deployment job ${DEPLOYMENT_NAME} to LIVE"
run "${FUSION[@]}" deployment run -n "${DEPLOYMENT_NAME}" -e LIVE

step "Switching to LIVE"
run "${FUSION[@]}" environment switch -n LIVE

# If BOTH connection-override credentials are set, import the override before
# re-enabling the event. If either is missing/empty, this step is skipped.
# (The :- default keeps `set -u` from erroring when the vars are unset.)
if [[ -n "${CONNECTION_USERNAME:-}" && -n "${CONNECTION_PASSWORD:-}" ]]; then
  step "Importing connection override (CONNECTION_USERNAME/PASSWORD are set)"
  run "${FUSION[@]}" project connection override import -i http_server_override.json
fi

step "Activating project event in LIVE"
run "${FUSION[@]}" project event enable -n "${PROJECT}" -in "${FLOW}" -cn "${DATA_PLANE}"

step "Logging out"
run "${FUSION[@]}" auth logout

echo ""
echo "==> Deployment complete: ${DEPLOYMENT_NAME}"

# ==========================================================================
# Sample successful run (VER=V69)
# ==========================================================================
#
# item-ax36068:Promote Integration Project To Live Script leorbrenman$ ./deploy_LBclitest_to_LIVE.sh
# ==> Logging in as leor.brenman@gmail.com
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar auth login -u leor.brenman@gmail.com -p ******** --url https://axway-appc-se.sandbox.fusion.services.axway.com/
# Welcome Leor Brenman GM!. You are now set to use Amplify Fusion operations.
# ==> Deactivating project event (LBclitest/flow1)
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project event disable -n LBclitest -in flow1 -cn "Shared Data Plane"
# Event stopped successfully.
# ==> Creating deployment job: LBclitest_dj_V69
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar deployment create -n LBclitest_dj_V69 -d LBclitest_dj_V69 -pv LBclitest,V69
# Successfully created Deployment Job
# ==> Switching to LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar environment switch -n LIVE
# Environment is changed to LIVE
# ==> Deactivating project event in LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project event disable -n LBclitest -in flow1 -cn "Shared Data Plane"
# Event stopped successfully.
# ==> Switching to DESIGN
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar environment switch -n DESIGN
# Environment is changed to DESIGN
# ==> Running deployment job LBclitest_dj_V69 to LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar deployment run -n LBclitest_dj_V69 -e LIVE
# Deployment Job LBclitest_dj_V69 executed successfully.
# ==> Switching to LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar environment switch -n LIVE
# Environment is changed to LIVE
# ==> Activating project event in LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project event enable -n LBclitest -in flow1 -cn "Shared Data Plane"
# Event started successfully
# ==> Logging out
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar auth logout
# User Brenman GM Leor is successfully logged out
# ==> Deployment complete: LBclitest_dj_V69
# item-ax36068:Promote Integration Project To Live Script leorbrenman$
