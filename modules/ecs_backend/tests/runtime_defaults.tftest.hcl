mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name   = "eu-west-1"
      region = "eu-west-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  alb_arn_suffix            = "app/test-alb/1234567890abcdef"
  target_group_arn          = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:targetgroup/app/1234567890abcdef"
  target_group_arn_suffix   = "targetgroup/app/1234567890abcdef"
  private_subnet_ids        = ["subnet-11111111", "subnet-22222222"]
  service_security_group_id = "sg-11111111"
  container_image           = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/app@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}

run "default_backend_service_is_private_and_scaled" {
  command = plan

  assert {
    condition     = aws_ecs_service.this.launch_type == "FARGATE"
    error_message = "Backend ECS module should use Fargate."
  }

  assert {
    condition     = aws_ecs_service.this.network_configuration[0].assign_public_ip == false
    error_message = "Backend ECS module should keep tasks private."
  }

  assert {
    condition     = aws_ecs_service.this.desired_count == 2
    error_message = "Backend ECS module should default to two tasks."
  }

  assert {
    condition     = aws_ecs_task_definition.this.runtime_platform[0].cpu_architecture == "ARM64"
    error_message = "Backend ECS tasks should default to ARM64."
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.exec) == 0
    error_message = "ECS Exec log group should not exist unless ECS Exec is enabled."
  }
}

run "ecs_exec_enables_cluster_exec_logging" {
  command = plan

  variables {
    enable_execute_command = true
    exec_kms_key_arn       = "arn:aws:kms:eu-west-1:123456789012:key/abcd1234-abcd-1234-abcd-1234567890ab"
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.exec) == 1
    error_message = "ECS Exec log group should be created when ECS Exec is enabled."
  }

  assert {
    condition     = aws_ecs_cluster.this.configuration[0].execute_command_configuration[0].logging == "OVERRIDE"
    error_message = "ECS cluster should override exec logging when ECS Exec is enabled."
  }
}

run "environment_suffix_changes_runtime_names" {
  command = plan

  variables {
    enable_environment_suffix = true
    environment_name_override = "staging"
  }

  assert {
    condition     = aws_ecs_cluster.this.name == "app-backend-cluster-staging"
    error_message = "Cluster name should include the environment suffix."
  }

  assert {
    condition     = aws_ecs_service.this.name == "app-backend-service-staging"
    error_message = "Service name should include the environment suffix."
  }
}
