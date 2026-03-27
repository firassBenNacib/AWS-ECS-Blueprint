mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-west-1"
      name   = "eu-west-1"
    }
  }
}

variables {
  cluster_arn                = "arn:aws:ecs:eu-west-1:123456789012:cluster/test-cluster"
  cluster_name               = "test-cluster"
  private_subnet_ids         = ["subnet-11111111", "subnet-22222222"]
  service_security_group_ids = ["sg-11111111"]
  service_name               = "orders"
  task_family                = "orders"
  execution_role_name        = "orders-execution"
  task_role_name             = "orders-task"
  container_name             = "orders"
  container_image            = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/orders@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  container_port             = 8080
  log_group_name             = "/aws/ecs/orders"
}

run "service_defaults_are_private_and_fargate" {
  command = plan

  assert {
    condition     = aws_ecs_service.this.launch_type == "FARGATE"
    error_message = "ECS service should use Fargate launch type."
  }

  assert {
    condition     = aws_ecs_service.this.network_configuration[0].assign_public_ip == false
    error_message = "ECS service should not assign a public IP by default."
  }

  assert {
    condition     = aws_ecs_service.this.enable_execute_command == false
    error_message = "ECS Exec should be disabled by default."
  }
}

run "autoscaling_defaults_are_applied" {
  command = plan

  assert {
    condition     = aws_appautoscaling_target.service.min_capacity == 1
    error_message = "Autoscaling min capacity should default to 1."
  }

  assert {
    condition     = aws_appautoscaling_target.service.max_capacity == 2
    error_message = "Autoscaling max capacity should default to 2."
  }

  assert {
    condition     = aws_appautoscaling_policy.cpu.target_tracking_scaling_policy_configuration[0].target_value == 70
    error_message = "CPU autoscaling target should default to 70."
  }

  assert {
    condition     = aws_appautoscaling_policy.memory.target_tracking_scaling_policy_configuration[0].target_value == 75
    error_message = "Memory autoscaling target should default to 75."
  }
}

run "load_balancer_and_service_discovery_are_opt_in" {
  command = plan

  assert {
    condition     = length(aws_ecs_service.this.load_balancer) == 0
    error_message = "Load balancer registration should be opt-in."
  }

  assert {
    condition     = length(aws_ecs_service.this.service_registries) == 0
    error_message = "Service discovery registration should be opt-in."
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.exec) == 0
    error_message = "ECS Exec log group should not exist by default."
  }
}

run "exec_logging_enables_audit_log_group" {
  command = plan

  variables {
    enable_execute_command = true
    exec_log_group_name    = "/aws/ecs/orders-exec"
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.exec) == 1
    error_message = "Enabling ECS Exec with an exec log group name should create the audit log group."
  }

  assert {
    condition     = aws_cloudwatch_log_group.exec[0].name == "/aws/ecs/orders-exec"
    error_message = "ECS Exec log group should use the provided name."
  }
}
