package terratest

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	ttlogger "github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/shell"
)

func TestLiveValidationE2E(t *testing.T) {
	repoRoot := getEnvOrDefault("E2E_REPO_ROOT", repoRootFromHere(t))
	terraformRoot := requireEnvOrSkip(t, "E2E_TERRAFORM_ROOT")
	awsRegion := requireEnvOrSkip(t, "E2E_AWS_REGION")
	runLabel := fmt.Sprintf("%d", time.Now().UTC().Unix())
	baseLogDir := getEnvOrDefault(
		"E2E_LOG_DIR",
		filepath.Join(os.TempDir(), "aws-ecs-blueprint-terratest", sanitizeName(filepath.Base(terraformRoot)), runLabel),
	)
	retries := getEnvIntOrDefault("E2E_TERRATEST_RETRIES", 0)

	type scenario struct {
		name         string
		tfvarsEnvVar string
		smokeProfile string
		required     bool
	}

	scenarios := []scenario{
		{
			name:         "default",
			tfvarsEnvVar: "E2E_TFVARS_FILE",
			smokeProfile: requireEnvOrSkip(t, "E2E_SMOKE_PROFILE"),
			required:     true,
		},
		{
			name:         "frontend-ecs",
			tfvarsEnvVar: "E2E_FRONTEND_ECS_TFVARS_FILE",
			smokeProfile: getEnvOrDefault("E2E_FRONTEND_ECS_SMOKE_PROFILE", "app"),
			required:     false,
		},
		{
			name:         "public-alb-restricted",
			tfvarsEnvVar: "E2E_PUBLIC_ALB_RESTRICTED_TFVARS_FILE",
			smokeProfile: getEnvOrDefault("E2E_PUBLIC_ALB_RESTRICTED_SMOKE_PROFILE", "app"),
			required:     false,
		},
	}

	for _, scenario := range scenarios {
		scenario := scenario
		tfvarsFile := strings.TrimSpace(os.Getenv(scenario.tfvarsEnvVar))
		if tfvarsFile == "" {
			if scenario.required {
				t.Skipf("%s is not set", scenario.tfvarsEnvVar)
			}
			continue
		}

		t.Run(scenario.name, func(t *testing.T) {
			logDir := baseLogDir
			if scenario.name != "default" {
				logDir = filepath.Join(baseLogDir, sanitizeName(scenario.name))
			}

			runLiveValidationScenario(
				t,
				repoRoot,
				terraformRoot,
				tfvarsFile,
				awsRegion,
				scenario.smokeProfile,
				logDir,
				retries,
			)
		})
	}
}

func requireEnvOrSkip(t *testing.T, key string) string {
	t.Helper()
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		t.Skipf("%s is not set", key)
	}
	return value
}

func getEnvOrDefault(key, fallback string) string {
	if value := strings.TrimSpace(os.Getenv(key)); value != "" {
		return value
	}
	return fallback
}

func getEnvIntOrDefault(key string, fallback int) int {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func repoRootFromHere(t *testing.T) string {
	t.Helper()
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("resolve cwd: %v", err)
	}
	return filepath.Clean(filepath.Join(cwd, "..", ".."))
}

func sanitizeName(value string) string {
	replacer := strings.NewReplacer("/", "-", "\\", "-", " ", "-", "_", "-")
	return replacer.Replace(strings.ToLower(value))
}

func assertFileExists(t *testing.T, path string) {
	t.Helper()
	if _, err := os.Stat(path); err != nil {
		t.Fatalf("expected artifact %s to exist: %v", path, err)
	}
}

func runLiveValidationScenario(
	t *testing.T,
	repoRoot string,
	terraformRoot string,
	tfvarsFile string,
	awsRegion string,
	smokeProfile string,
	logDir string,
	retries int,
) {
	t.Helper()

	if err := os.MkdirAll(logDir, 0o755); err != nil {
		t.Fatalf("create terratest log dir: %v", err)
	}

	cmd := shell.Command{
		Command: "bash",
		Args: []string{
			".scripts/run_live_validation.sh",
			"--path", terraformRoot,
			"--tfvars-file", tfvarsFile,
			"--aws-region", awsRegion,
			"--smoke-profile", smokeProfile,
			"--log-dir", logDir,
		},
		WorkingDir: repoRoot,
	}

	description := fmt.Sprintf("live validation for %s (%s)", filepath.Base(terraformRoot), filepath.Base(logDir))
	ttlogger.Logf(t, "Running %s with logs in %s", description, logDir)

	_, err := retry.DoWithRetryE(t, description, retries, 15*time.Second, func() (string, error) {
		return shell.RunCommandAndGetOutputE(t, cmd)
	})
	if err != nil {
		logKnownArtifacts(t, logDir)
		t.Fatalf("%s failed: %v", description, err)
	}

	assertFileExists(t, filepath.Join(logDir, "init.log"))
	assertFileExists(t, filepath.Join(logDir, "apply.log"))
	assertFileExists(t, filepath.Join(logDir, "smoke.log"))
	assertFileExists(t, filepath.Join(logDir, "destroy.log"))
}

func logKnownArtifacts(t *testing.T, logDir string) {
	t.Helper()
	for _, name := range []string{"init.log", "apply.log", "smoke.log", "destroy-init.log", "destroy.log", "state.log"} {
		path := filepath.Join(logDir, name)
		content, err := os.ReadFile(path)
		if err != nil {
			continue
		}
		ttlogger.Logf(t, "===== %s =====\n%s", name, string(content))
	}
}
