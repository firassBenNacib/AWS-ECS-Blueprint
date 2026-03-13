.DEFAULT_GOAL := help

ROOT_DIR ?= $(CURDIR)
SCRIPT_DIR := .scripts
LOCAL_BIN_DIR := $(ROOT_DIR)/.tmp-bin
DOCS_GATE_SCRIPT := $(SCRIPT_DIR)/terraform_docs_gate.sh
INSTALL_TERRAFORM_DOCS_SCRIPT := $(SCRIPT_DIR)/install_terraform_docs.sh
SECURITY_SCAN_SCRIPT := $(SCRIPT_DIR)/security_scan_prod.sh
VALIDATE_MODULES_SCRIPT := $(SCRIPT_DIR)/validate_modules.sh
CHECK_BACKEND_KEYS_SCRIPT := $(SCRIPT_DIR)/check_backend_key_strategy.sh
SAFE_DESTROY_SCRIPT := $(SCRIPT_DIR)/safe_destroy_app_root.sh

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
	printf "Available targets:\n\n"
	printf "  %-18s %s\n" "fmt" "Format Terraform recursively"
	printf "  %-18s %s\n" "fmt-check" "Check Terraform formatting"
	printf "  %-18s %s\n" "validate" "Validate deployment roots and reusable modules"
	printf "  %-18s %s\n" "validate-targets" "Validate deployable Terraform roots"
	printf "  %-18s %s\n" "validate-modules" "Validate reusable modules"
	printf "  %-18s %s\n" "docs" "Rebuild documentation under DOCS_PATH (default: modules)"
	printf "  %-18s %s\n" "docs-check" "Check documentation drift under DOCS_PATH"
	printf "  %-18s %s\n" "scan-targets" "Run local security scans for deployable Terraform roots"
	printf "  %-18s %s\n" "clean-local" "Remove generated local reports, tool caches, and Terraform workdirs"
	printf "  %-18s %s\n" "list-targets" "Print deployable Terraform roots"
	printf "  %-18s %s\n" "check-backend-keys" "Verify each deployment root uses a distinct backend state key (required for production)"
	printf "  %-18s %s\n" "safe-destroy-root" "Safely destroy one app root: make safe-destroy-root ROOT=prod-app [CLEANUP_SECRETS=true]"

.PHONY: ensure-plugin-cache
ensure-plugin-cache:
	mkdir -p "$(TF_PLUGIN_CACHE_DIR)"

.PHONY: ensure-terraform-docs
ensure-terraform-docs:
	TERRAFORM_DOCS_VERSION="$(TERRAFORM_DOCS_VERSION)" LOCAL_BIN_DIR="$(LOCAL_BIN_DIR)" \
		bash "$(INSTALL_TERRAFORM_DOCS_SCRIPT)"

.PHONY: list-targets
list-targets:
	printf "%s\n" $(TARGET_DIRS)

.PHONY: fmt
fmt:
	$(TF_BIN) fmt -recursive .

.PHONY: fmt-check
fmt-check:
	$(TF_BIN) fmt -check -recursive .

.PHONY: validate
validate: validate-targets validate-modules

.PHONY: validate-targets
validate-targets: ensure-plugin-cache
	for dir in $(TARGET_DIRS); do \
		if [[ ! -f "$$dir/.terraform/modules/modules.json" || ! -d "$$dir/.terraform/providers" ]]; then \
			TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" $(TF_BIN) -chdir="$$dir" init -backend=false -input=false -lockfile=readonly >/dev/null; \
		fi; \
		TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" $(TF_BIN) -chdir="$$dir" validate; \
	done

.PHONY: validate-modules
validate-modules: ensure-plugin-cache
	TF_PLUGIN_CACHE_DIR="$(TF_PLUGIN_CACHE_DIR)" bash "$(VALIDATE_MODULES_SCRIPT)"

.PHONY: docs
docs: ensure-terraform-docs
	bash "$(DOCS_GATE_SCRIPT)" write "$(DOCS_PATH)"
	printf "Documentation rebuilt for %s.\n" "$(DOCS_PATH)"

.PHONY: docs-check
docs-check: ensure-terraform-docs
	bash "$(DOCS_GATE_SCRIPT)" check "$(DOCS_PATH)"
	printf "Documentation drift check passed for %s.\n" "$(DOCS_PATH)"

.PHONY: scan-targets
scan-targets:
	for dir in $(TARGET_DIRS); do \
		OUT_DIR="security-reports/$$dir" bash "$(SECURITY_SCAN_SCRIPT)" "$$dir/terraform.tfvars.example" "$$dir"; \
	done

.PHONY: clean-local
clean-local:
	bash "$(SCRIPT_DIR)/clean_local_artifacts.sh"

.PHONY: check-backend-keys
check-backend-keys:
	bash "$(CHECK_BACKEND_KEYS_SCRIPT)" "$(ROOT_DIR)"

.PHONY: safe-destroy-root
safe-destroy-root:
	: "$${ROOT:?Usage: make safe-destroy-root ROOT=prod-app [TFVARS=terraform.tfvars] [CLEANUP_SECRETS=true]}"
	TFVARS="$${TFVARS:-terraform.tfvars}"
	CLEANUP_FLAG=""
	if [[ "$${CLEANUP_SECRETS:-false}" == "true" ]]; then
		CLEANUP_FLAG="--cleanup-secrets"
	fi
	bash "$(SAFE_DESTROY_SCRIPT)" --root "$(ROOT_DIR)/$${ROOT}" --tfvars "$${TFVARS}" $$CLEANUP_FLAG
