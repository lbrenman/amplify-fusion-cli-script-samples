#!/usr/bin/env bash
#
# Fusion deployment script to run after versioning a project in DESIGN to deploy it to LIVE
#
# It is for a Fusion project: LBclitest2, with an API: EchoAPI, and a single data plane: Shared Data Plane
#
# Requires three environment variables set OUTSIDE this script:
#   VER       e.g. V2
#   USERNAME  e.g. leor.brenman@gmail.com
#   PASSWORD  your password
#
# Example:
#   export VER=V2
#   export USERNAME=leor.brenman@gmail.com
#   export PASSWORD='...'
#   ./deploy_LBclitest2_to_LIVE.sh
#
# See the bottom of this file for a sample successful run.
#
# -e            exit immediately if any command fails
# -u            treat use of an unset variable as an error
# -o pipefail   a pipeline fails if any element fails
#
# NOTE: The two API deactivation steps use `run_soft`, which warns but does
# NOT stop the script if the command fails. This tolerates the harmless
# "activationData is null" error that occurs when the API is already
# deactivated. All other steps use `run` and will halt on any failure.
set -euo pipefail

# --- Configuration --------------------------------------------------------
# The `fusion` alias from your interactive shell is NOT available inside a
# script, so we define the command here as an array. Override it if needed:
#   export FUSION_JAR=/path/to/fusion-cli-1.0.0-runner.jar
FUSION_JAR="${FUSION_JAR:-/Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar}"
FUSION=(java -jar "${FUSION_JAR}")

URL="https://axway-appc-se.sandbox.fusion.services.axway.com/"
PROJECT="LBclitest2"
API="EchoAPI"
DATA_PLANE="Shared Data Plane"

# --- Validate required environment variables ------------------------------
: "${VER:?Environment variable VER is not set (e.g. export VER=V2)}"
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

# --- Helper: print the command with the password masked -------------------
_print_cmd() {
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
}

# --- Helper: required command — print, run, and STOP on failure -----------
run() {
  _print_cmd "$@"
  "$@"
}

# --- Helper: optional command — print, run, WARN but continue on failure --
# Using `if "$@"; then` suspends `set -e` for this command so we can catch
# a non-zero exit and keep going instead of aborting the script.
run_soft() {
  _print_cmd "$@"
  if "$@"; then
    return 0
  else
    local rc=$?
    echo "    [warning] command exited with status ${rc} — continuing anyway"
    return 0
  fi
}

# --- Deployment steps -----------------------------------------------------

step "Logging in as ${USERNAME}"
run "${FUSION[@]}" auth login -u "${USERNAME}" -p "${PASSWORD}" --url "${URL}"

step "Locking project (${PROJECT}) in DESIGN"
run "${FUSION[@]}" project lock enable -n "${PROJECT}"

step "Deactivating API ${API} in DESIGN (non-fatal)"
run_soft "${FUSION[@]}" project api deactivate -n "${PROJECT}" -an "${API}" -cn "${DATA_PLANE}"

step "Creating deployment job: ${DEPLOYMENT_NAME}"
run "${FUSION[@]}" deployment create \
  -n "${DEPLOYMENT_NAME}" \
  -d "${DEPLOYMENT_NAME}" \
  -pv "${PROJECT_VERSION}"

step "Unlocking project (${PROJECT}) in DESIGN"
run "${FUSION[@]}" project lock disable -n "${PROJECT}"

step "Switching to LIVE"
run "${FUSION[@]}" environment switch -n LIVE

step "Locking project (${PROJECT}) in LIVE"
run "${FUSION[@]}" project lock enable -n "${PROJECT}"

step "Deactivating API ${API} in LIVE (non-fatal)"
run_soft "${FUSION[@]}" project api deactivate -n "${PROJECT}" -an "${API}" -cn "${DATA_PLANE}"

step "Switching to DESIGN"
run "${FUSION[@]}" environment switch -n DESIGN

step "Running deployment job ${DEPLOYMENT_NAME} to LIVE"
run "${FUSION[@]}" deployment run -n "${DEPLOYMENT_NAME}" -e LIVE

step "Switching to LIVE"
run "${FUSION[@]}" environment switch -n LIVE

step "Activating API ${API} in LIVE"
run "${FUSION[@]}" project api activate -n "${PROJECT}" -an "${API}" -cn "${DATA_PLANE}"

step "Unlocking project (${PROJECT}) in LIVE"
run "${FUSION[@]}" project lock disable -n "${PROJECT}"

step "Logging out"
run "${FUSION[@]}" auth logout

echo ""
echo "==> Deployment complete: ${DEPLOYMENT_NAME}"

# ==========================================================================
# Sample successful run (VER=V6)
# ==========================================================================
#
# item-ax36068:Promote API Project To Live Script leorbrenman$ ./deploy_LBclitest2_to_LIVE.sh
# ==> Logging in as leor.brenman@gmail.com
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar auth login -u leor.brenman@gmail.com -p ******** --url https://axway-appc-se.sandbox.fusion.services.axway.com/
# Welcome Leor Brenman GM!. You are now set to use Amplify Fusion operations.
# ==> Locking project (LBclitest2) in DESIGN
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project lock enable -n LBclitest2
# Project LBclitest2 successfully locked
# ==> Deactivating API EchoAPI in DESIGN (non-fatal)
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project api deactivate -n LBclitest2 -an EchoAPI -cn "Shared Data Plane"
# API Deactivated
# ==> Creating deployment job: LBclitest2_dj_V6
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar deployment create -n LBclitest2_dj_V6 -d LBclitest2_dj_V6 -pv LBclitest2,V6
# Successfully created Deployment Job
# ==> Unlocking project (LBclitest2) in DESIGN
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project lock disable -n LBclitest2
# Project LBclitest2 successfully unlocked
# ==> Switching to LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar environment switch -n LIVE
# Environment is changed to LIVE
# ==> Locking project (LBclitest2) in LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project lock enable -n LBclitest2
# Project LBclitest2 successfully locked
# ==> Deactivating API EchoAPI in LIVE (non-fatal)
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project api deactivate -n LBclitest2 -an EchoAPI -cn "Shared Data Plane"
# API Deactivated
# ==> Switching to DESIGN
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar environment switch -n DESIGN
# Environment is changed to DESIGN
# ==> Running deployment job LBclitest2_dj_V6 to LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar deployment run -n LBclitest2_dj_V6 -e LIVE
# Deployment Job LBclitest2_dj_V6 executed successfully.
# ==> Switching to LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar environment switch -n LIVE
# Environment is changed to LIVE
# ==> Activating API EchoAPI in LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project api activate -n LBclitest2 -an EchoAPI -cn "Shared Data Plane"
# API is activated successfully
# ==> Unlocking project (LBclitest2) in LIVE
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar project lock disable -n LBclitest2
# Project LBclitest2 successfully unlocked
# ==> Logging out
#     $ java -jar /Users/leorbrenman/Downloads/fusion-cli-1.0.0-runner.jar auth logout
# User Brenman GM Leor is successfully logged out
# ==> Deployment complete: LBclitest2_dj_V6
# item-ax36068:Promote API Project To Live Script leorbrenman$
