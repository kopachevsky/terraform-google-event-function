#!/usr/bin/env bash

# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Always clean up.
DELETE_AT_EXIT="$(mktemp -d)"
finish() {
  echo 'BEGIN: finish() trap handler' >&2
  kitchen destroy
  [[ -d "${DELETE_AT_EXIT}" ]] && rm -rf "${DELETE_AT_EXIT}"
  echo 'END: finish() trap handler' >&2
}

# Map the input parameters provided by Concourse CI, or whatever mechanism is
# running the tests to Terraform input variables.  Also setup credentials for
# use with kitchen-terraform, inspec, and gcloud.
setup_environment() {
  local tmpfile
  tmpfile="$(mktemp)"
  echo "${SERVICE_ACCOUNT_JSON}" > "${tmpfile}"

  # gcloud variables
  export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE="${tmpfile}"
  # Application default credentials (Terraform google provider and inspec-gcp)
  export GOOGLE_APPLICATION_CREDENTIALS="${tmpfile}"

  # Terraform variables
  export TF_VAR_project_id="${PROJECT_ID}"
  export TF_VAR_region="${REGION:-us-east1}"
  export TF_VAR_zone="${ZONE:-us-east1-b}"

  # Stubs for module/*. Use for terraform linter
  export TF_VAR_entry_point=""
  export TF_VAR_event_trigger="{event_type=\"\",resource=\"\"}"
  export TF_VAR_name="test"
  export TF_VAR_runtime=""
  export TF_VAR_source_directory=""
  export TF_VAR_source_repository_url=""
  export TF_VAR_filter=""
}

main() {
  set -eu
  # Setup trap handler to auto-cleanup
  export TMPDIR="${DELETE_AT_EXIT}"
  trap finish EXIT

  # Setup environment variables
  setup_environment
  set -x

  # Execute the test lifecycle
  kitchen verify
}

# if script is being executed and not sourced.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
