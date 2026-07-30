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
# Example:
#   export VER=V66
#   export USERNAME=leor.brenman@gmail.com
#   export PASSWORD='...'
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

step "Switching to DESIGN"
run "${FUSION[@]}" environment switch -n DESIGN

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

step "Activating project event in LIVE"
run "${FUSION[@]}" project event enable -n "${PROJECT}" -in "${FLOW}" -cn "${DATA_PLANE}"

echo ""
echo "==> Deployment complete: ${DEPLOYMENT_NAME}"

# ==========================================================================
# Sample successful run (VER=V67)
# ==========================================================================
#
# LBrenman-MBA15:Downloads leorbrenman$ ./deploy_LBclitest_to_LIVE.sh
# ==> Logging in as leor.brenman@gmail.com
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar auth login -u leor.brenman@gmail.com -p ******** --url https://axway-appc-se.sandbox.fusion.services.axway.com/
# Welcome Leor Brenman GM!. You are now set to use Amplify Fusion operations.
# ==> Switching to DESIGN
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar environment switch -n DESIGN
# You are already in the same environment!!.
# ==> Deactivating project event (LBclitest/flow1)
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project event disable -n LBclitest -in flow1 -cn "Shared Data Plane"
# Event is not enabled for integration flow
# ==> Creating deployment job: LBclitest_dj_V67
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar deployment create -n LBclitest_dj_V67 -d LBclitest_dj_V67 -pv LBclitest,V67
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
# ==> Running deployment job LBclitest_dj_V67 to LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar deployment run -n LBclitest_dj_V67 -e LIVE
# Deployment Job LBclitest_dj_V67 executed successfully.
# ==> Switching to LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar environment switch -n LIVE
# Environment is changed to LIVE
# ==> Activating project event in LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project event enable -n LBclitest -in flow1 -cn "Shared Data Plane"
# Event started successfully
# ==> Deployment complete: LBclitest_dj_V67
# LBrenman-MBA15:Downloads leorbrenman$
