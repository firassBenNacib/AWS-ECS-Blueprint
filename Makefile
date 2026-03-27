.DEFAULT_GOAL := help

ROOT_DIR ?= $(CURDIR)
SCRIPT_DIR := .scripts
LOCAL_BIN_DIR := $(ROOT_DIR)/.tmp-bin
DOCS_GATE_SCRIPT := $(SCRIPT_DIR)/terraform_docs_gate.sh
INSTALL_TERRAFORM_DOCS_SCRIPT := $(SCRIPT_DIR)/install_terraform_docs.sh
SECURITY_SCAN_SCRIPT := $(SCRIPT_DIR)/security_scan_prod.sh
VALIDATE_MODULES_SCRIPT := $(SCRIPT_DIR)/validate_modules.sh
VALIDATE_MODULE_SCRIPT := $(SCRIPT_DIR)/validate_module.sh
VALIDATE_TARGETS_SCRIPT := $(SCRIPT_DIR)/validate_targets.sh
TEST_MODULES_SCRIPT := $(SCRIPT_DIR)/test_modules.sh
TEST_ROOTS_SCRIPT := $(SCRIPT_DIR)/test_roots.sh
CHECK_BACKEND_KEYS_SCRIPT := $(SCRIPT_DIR)/check_backend_key_strategy.sh
SAFE_DESTROY_SCRIPT := $(SCRIPT_DIR)/safe_destroy_app_root.sh
INIT_APP_ROOT_SCRIPT := $(SCRIPT_DIR)/init_app_root.sh
TAG_REPORT_SCRIPT := $(SCRIPT_DIR)/report_terraform_tag_gaps.py
ROOT_PARITY_SCRIPT := $(SCRIPT_DIR)/check_root_parity.py

TARGET_DIRS := prod-app nonprod-app

TF_PLUGIN_CACHE_DIR ?= $(ROOT_DIR)/.terraform.d/plugin-cache
TERRAFORM_DOCS_VERSION ?= v0.21.0
DOCS_GOAL_PATH := $(word 2,$(MAKECMDGOALS))
ifeq ($(firstword $(MAKECMDGOALS)),docs)
DOCS_PATH ?= $(if $(DOCS_GOAL_PATH),$(DOCS_GOAL_PATH),modules)
endif
ifeq ($(firstword $(MAKECMDGOALS)),docs-check)
DOCS_PATH ?= $(if $(DOCS_GOAL_PATH),$(DOCS_GOAL_PATH),modules)
endif
DOCS_PATH ?= modules
export PATH := $(LOCAL_BIN_DIR):$(PATH)
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
.SILENT:

TF_BIN ?= terraform
TF_WITH_PLUGIN_CACHE = TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" $(TF_BIN)

.PHONY: help
help:
	printf '%s\n\n' 'Available targets'
	printf '%s\n' 'Formatting'
	printf '  %-22s %s\n' 'fmt' 'Format Terraform files'
	printf '  %-22s %s\n' 'fmt-check' 'Check Terraform formatting'
	printf '\n%s\n' 'Initialization'
	printf '  %-22s %s\n' 'init-root' 'Initialize one deployment root'
	printf '  %-22s %s\n' 'init-roots' 'Initialize all deployment roots'
	printf '\n%s\n' 'Validation'
	printf '  %-22s %s\n' 'validate' 'Validate roots and reusable modules'
	printf '  %-22s %s\n' 'validate-root' 'Validate one deployment root'
	printf '  %-22s %s\n' 'validate-roots' 'Validate all deployment roots'
	printf '  %-22s %s\n' 'validate-module' 'Validate one reusable module'
	printf '  %-22s %s\n' 'validate-modules' 'Validate all reusable modules'
	printf '  %-22s %s\n' 'check-root-parity' 'Check prod and nonprod root parity'
	printf '\n%s\n' 'Tests'
	printf '  %-22s %s\n' 'test-modules' 'Run native Terraform tests for reusable modules'
	printf '  %-22s %s\n' 'test-module' 'Run native Terraform tests for one reusable module'
	printf '  %-22s %s\n' 'test-root' 'Run native Terraform tests for one deployment root'
	printf '  %-22s %s\n' 'test-roots' 'Run native Terraform tests for all deployment roots'
	printf '\n%s\n' 'Scans'
	printf '  %-22s %s\n' 'scan-root' 'Run local security scans for one deployment root'
	printf '  %-22s %s\n' 'scan-roots' 'Run local security scans for all deployment roots'
	printf '  %-22s %s\n' 'ci-root' 'Run the main local quality gates for one root'
	printf '  %-22s %s\n' 'ci-local' 'Run the main local quality gates'
	printf '\n%s\n' 'Plans'
	printf '  %-22s %s\n' 'plan-root' 'Plan one deployment root'
	printf '  %-22s %s\n' 'plan-roots' 'Plan all deployment roots'
	printf '\n%s\n' 'Tags'
	printf '  %-22s %s\n' 'tag-plan-root' 'Report AWS tag coverage from a root plan'
	printf '  %-22s %s\n' 'tag-state-root' 'Report AWS tag coverage from a root state'
	printf '\n%s\n' 'Docs'
	printf '  %-22s %s\n' 'docs' 'Rebuild terraform-docs output'
	printf '  %-22s %s\n' 'docs-check' 'Check terraform-docs drift'
	printf '\n%s\n' 'Destroy'
	printf '  %-22s %s\n' 'destroy-root' 'Guarded destroy for one deployment root'
	printf '  %-22s %s\n' 'destroy-roots' 'Guarded destroy for all deployment roots'
	printf '\n%s\n' 'Operations'
	printf '  %-22s %s\n' 'list-roots' 'List deployment roots'
	printf '  %-22s %s\n' 'check-backend-keys' 'Verify distinct backend state keys per root'
	printf '  %-22s %s\n' 'clean-local' 'Remove generated reports, caches, and workdirs'

.PHONY: ensure-plugin-cache
ensure-plugin-cache:
	mkdir -p "$(TF_PLUGIN_CACHE_DIR)"

.PHONY: ensure-terraform-docs
ensure-terraform-docs:
	TERRAFORM_DOCS_VERSION="$(TERRAFORM_DOCS_VERSION)" LOCAL_BIN_DIR="$(LOCAL_BIN_DIR)" \
		bash "$(INSTALL_TERRAFORM_DOCS_SCRIPT)"

.PHONY: list-roots list-targets
list-roots list-targets:
	printf "%s\n" $(TARGET_DIRS)

.PHONY: fmt
fmt:
	$(TF_BIN) fmt -recursive .
	printf "Terraform formatting completed.\n"

.PHONY: fmt-check
fmt-check:
	$(TF_BIN) fmt -check -recursive .
	printf "Terraform formatting check passed.\n"

.PHONY: init
init: init-roots

.PHONY: init-root
init-root: ensure-plugin-cache
	if [[ -z "$${ROOT:-}" ]]; then \
		printf "Refusing to initialize one root without ROOT=...\n" >&2; \
		printf "Usage: make init-root ROOT=prod-app\n" >&2; \
		exit 2; \
	fi
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(INIT_APP_ROOT_SCRIPT)" --root "$${ROOT}"
	printf "Deployment root initialization completed for: %s\n" "$${ROOT}"

.PHONY: init-roots
init-roots: ensure-plugin-cache
	for dir in $(TARGET_DIRS); do \
		TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(INIT_APP_ROOT_SCRIPT)" --root "$$dir"; \
	done
	printf "Deployment root initialization completed for: %s\n" "$(TARGET_DIRS)"

.PHONY: validate
validate: validate-roots validate-modules

.PHONY: validate-roots validate-targets
validate-roots validate-targets: ensure-plugin-cache
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(VALIDATE_TARGETS_SCRIPT)" $(TARGET_DIRS)
	printf "Deployment root validation passed for: %s\n" "$(TARGET_DIRS)"

.PHONY: validate-root
validate-root: ensure-plugin-cache
	if [[ -z "$${ROOT:-}" ]]; then \
		printf "Refusing to validate one root without ROOT=...\n" >&2; \
		printf "Usage: make validate-root ROOT=prod-app\n" >&2; \
		exit 2; \
	fi
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(VALIDATE_TARGETS_SCRIPT)" "$${ROOT}"
	printf "Deployment root validation passed for: %s\n" "$${ROOT}"

.PHONY: validate-modules
validate-modules: ensure-plugin-cache
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(VALIDATE_MODULES_SCRIPT)"
	printf "Reusable module validation passed.\n"

.PHONY: validate-module
validate-module: ensure-plugin-cache
	if [[ -z "$${MODULE:-}" ]]; then \
		printf "Refusing to validate one module without MODULE=...\n" >&2; \
		printf "Usage: make validate-module MODULE=application_platform\n" >&2; \
		exit 2; \
	fi; \
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(VALIDATE_MODULE_SCRIPT)" "$${MODULE}"
	printf "Reusable module validation passed for: %s\n" "$${MODULE}"

.PHONY: test test-modules
test test-modules: ensure-plugin-cache
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(TEST_MODULES_SCRIPT)"
	printf "Native Terraform tests passed.\n"

.PHONY: test-module
test-module: ensure-plugin-cache
	if [[ -z "$${MODULE:-}" ]]; then \
		printf "Refusing to test one module without MODULE=...\n" >&2; \
		printf "Usage: make test-module MODULE=application_platform\n" >&2; \
		exit 2; \
	fi; \
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(TEST_MODULES_SCRIPT)" "$${MODULE}"
	printf "Native Terraform tests passed for: %s\n" "$${MODULE}"

.PHONY: test-root
test-root: ensure-plugin-cache
	if [[ -z "$${ROOT:-}" ]]; then \
		printf "Refusing to test one root without ROOT=...\n" >&2; \
		printf "Usage: make test-root ROOT=prod-app\n" >&2; \
		exit 2; \
	fi
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(TEST_ROOTS_SCRIPT)" "$${ROOT}"
	printf "Native Terraform root tests passed for: %s\n" "$${ROOT}"

.PHONY: test-roots
test-roots: ensure-plugin-cache
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(TEST_ROOTS_SCRIPT)"
	printf "Native Terraform root tests passed.\n"

.PHONY: ci-local
ci-local: fmt-check docs-check check-root-parity validate test-modules test-roots scan-roots

.PHONY: ci-root
ci-root:
	if [[ -z "$${ROOT:-}" ]]; then \
		printf "Refusing to run one-root local checks without ROOT=...\n" >&2; \
		printf "Usage: make ci-root ROOT=prod-app\n" >&2; \
		exit 2; \
	fi
	$(MAKE) --no-print-directory fmt-check
	$(MAKE) --no-print-directory docs-check
	$(MAKE) --no-print-directory validate-root ROOT="$${ROOT}"
	$(MAKE) --no-print-directory test-root ROOT="$${ROOT}"
	$(MAKE) --no-print-directory scan-root ROOT="$${ROOT}" TFVARS="$${TFVARS:-$${ROOT}/terraform.tfvars.example}"

.PHONY: check-root-parity
check-root-parity:
	python3 "$(ROOT_PARITY_SCRIPT)"

.PHONY: plan-root
plan-root: ensure-plugin-cache
	if [[ -z "$${ROOT:-}" ]]; then \
		printf "Refusing to plan without ROOT=...\n" >&2; \
		printf "Usage: make plan-root ROOT=prod-app [TFVARS=terraform.tfvars]\n" >&2; \
		exit 2; \
	fi
	TFVARS="$${TFVARS:-terraform.tfvars}"
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(INIT_APP_ROOT_SCRIPT)" --root "$${ROOT}"
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" $(TF_BIN) -chdir="$${ROOT}" plan -input=false -lock-timeout=5m -compact-warnings -no-color -var-file="$$TFVARS"

.PHONY: plan-roots plan-all
plan-roots plan-all: ensure-plugin-cache
	for dir in $(TARGET_DIRS); do \
		$(MAKE) --no-print-directory plan-root ROOT="$$dir" TFVARS="$${TFVARS:-terraform.tfvars}"; \
	done

.PHONY: plan-prod
plan-prod: ensure-plugin-cache
	$(MAKE) --no-print-directory plan-root ROOT=prod-app TFVARS="$${TFVARS:-terraform.tfvars}"

.PHONY: plan-nonprod
plan-nonprod: ensure-plugin-cache
	$(MAKE) --no-print-directory plan-root ROOT=nonprod-app TFVARS="$${TFVARS:-terraform.tfvars}"

.PHONY: docs
docs: ensure-terraform-docs
	bash "$(DOCS_GATE_SCRIPT)" write "$(DOCS_PATH)"
	printf "Documentation rebuilt for %s.\n" "$(DOCS_PATH)"

.PHONY: docs-check
docs-check: ensure-terraform-docs
	bash "$(DOCS_GATE_SCRIPT)" check "$(DOCS_PATH)"
	printf "Documentation drift check passed for %s.\n" "$(DOCS_PATH)"

.PHONY: scan-root
scan-root:
	if [[ -z "$${ROOT:-}" ]]; then \
		printf "Refusing to scan one root without ROOT=...\n" >&2; \
		printf "Usage: make scan-root ROOT=prod-app [TFVARS=prod-app/terraform.tfvars.example]\n" >&2; \
		exit 2; \
	fi
	TFVARS="$${TFVARS:-$${ROOT}/terraform.tfvars.example}"
	OUT_DIR="$${OUT_DIR:-security-reports/$${ROOT}}" bash "$(SECURITY_SCAN_SCRIPT)" "$$TFVARS" "$${ROOT}"
	printf "Security scans passed for: %s\n" "$${ROOT}"

.PHONY: scan-roots scan-targets
scan-roots scan-targets:
	for dir in $(TARGET_DIRS); do \
		OUT_DIR="security-reports/$$dir" bash "$(SECURITY_SCAN_SCRIPT)" "$$dir/terraform.tfvars.example" "$$dir"; \
	done
	printf "Security scans passed for: %s\n" "$(TARGET_DIRS)"

.PHONY: tag-plan-root tag-report-plan
tag-plan-root tag-report-plan: ensure-plugin-cache
	if [[ -z "$${ROOT:-}" ]]; then \
		printf "Refusing to report plan tag coverage without ROOT=...\n" >&2; \
		printf "Usage: make tag-plan-root ROOT=prod-app [TFVARS=terraform.tfvars]\n" >&2; \
		exit 2; \
	fi
	TFVARS="$${TFVARS:-terraform.tfvars}"
	STRICT_FLAG=""
	if [[ "$${STRICT:-false}" == "true" ]]; then
		STRICT_FLAG="--fail-on-missing-tags"
	fi
	VERBOSE_UNSUPPORTED_FLAG=""
	if [[ "$${VERBOSE_UNSUPPORTED:-false}" == "true" ]]; then
		VERBOSE_UNSUPPORTED_FLAG="--verbose-unsupported"
	fi
	PLAN_FILE="$$(mktemp)"
	trap 'rm -f "$$PLAN_FILE"' EXIT
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(INIT_APP_ROOT_SCRIPT)" --root "$${ROOT}"
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" $(TF_BIN) -chdir="$${ROOT}" plan -input=false -lock-timeout=5m -refresh=false -compact-warnings -no-color -var-file="$$TFVARS" -out="$$PLAN_FILE" >/dev/null
	$(TF_BIN) -chdir="$${ROOT}" show -json "$$PLAN_FILE" | python3 "$(TAG_REPORT_SCRIPT)" --input - --source "plan:$${ROOT}" $$STRICT_FLAG $$VERBOSE_UNSUPPORTED_FLAG

.PHONY: tag-state-root tag-report-state
tag-state-root tag-report-state: ensure-plugin-cache
	if [[ -z "$${ROOT:-}" ]]; then \
		printf "Refusing to report state tag coverage without ROOT=...\n" >&2; \
		printf "Usage: make tag-state-root ROOT=prod-app\n" >&2; \
		exit 2; \
	fi
	STRICT_FLAG=""
	if [[ "$${STRICT:-false}" == "true" ]]; then
		STRICT_FLAG="--fail-on-missing-tags"
	fi
	VERBOSE_UNSUPPORTED_FLAG=""
	if [[ "$${VERBOSE_UNSUPPORTED:-false}" == "true" ]]; then
		VERBOSE_UNSUPPORTED_FLAG="--verbose-unsupported"
	fi
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(INIT_APP_ROOT_SCRIPT)" --root "$${ROOT}"
	$(TF_BIN) -chdir="$${ROOT}" show -json | python3 "$(TAG_REPORT_SCRIPT)" --input - --source "state:$${ROOT}" $$STRICT_FLAG $$VERBOSE_UNSUPPORTED_FLAG

.PHONY: clean-local
clean-local:
	bash "$(SCRIPT_DIR)/clean_local_artifacts.sh"

.PHONY: check-backend-keys
check-backend-keys:
	bash "$(CHECK_BACKEND_KEYS_SCRIPT)" "$(ROOT_DIR)"

.PHONY: destroy-root safe-destroy-root
destroy-root safe-destroy-root:
	if [[ -z "$${ROOT:-}" ]]; then \
		printf "Refusing to destroy without ROOT=...\n" >&2; \
		printf "Usage: make destroy-root ROOT=prod-app [TFVARS=terraform.tfvars] [CLEANUP_SECRETS=true]\n" >&2; \
		exit 2; \
	fi
	TFVARS="$${TFVARS:-terraform.tfvars}"
	CLEANUP_FLAG=""
	if [[ "$${CLEANUP_SECRETS:-false}" == "true" ]]; then
		CLEANUP_FLAG="--cleanup-secrets"
	fi
	bash "$(SAFE_DESTROY_SCRIPT)" --root "$(ROOT_DIR)/$${ROOT}" --tfvars "$${TFVARS}" $$CLEANUP_FLAG

.PHONY: destroy-roots
destroy-roots:
	if [[ "$${CONFIRM_ALL:-false}" != "true" ]]; then \
		printf "Refusing to destroy all roots without CONFIRM_ALL=true...\n" >&2; \
		printf "Usage: make destroy-roots CONFIRM_ALL=true [TFVARS=terraform.tfvars] [CLEANUP_SECRETS=true]\n" >&2; \
		exit 2; \
	fi
	for dir in $(TARGET_DIRS); do \
		$(MAKE) --no-print-directory destroy-root ROOT="$$dir" TFVARS="$${TFVARS:-terraform.tfvars}" CLEANUP_SECRETS="$${CLEANUP_SECRETS:-false}"; \
	done
