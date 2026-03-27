variables {
  runtime = {
    runtime_mode_is_micro           = true
    cost_optimized_dev_tier_enabled = false
    project_name                    = "example-app"
    environment_name                = "nonprod"
    aws_region                      = "eu-west-1"
    rds_db_name                     = "app"
    rds_username                    = "admin"
  }

  backend = {
    backend_env                     = {}
    backend_secret_arns             = {}
    backend_rds_secret_env_var_name = "DB_PASSWORD"
    backend_container_image         = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/example-app-backend@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    allowed_image_registries_final  = ["123456789012.dkr.ecr.eu-west-1.amazonaws.com"]
    microservice_allowed_registries = ["123456789012.dkr.ecr.eu-west-1.amazonaws.com"]
  }

  app_data = {
    address                = "example-app-nonprod.cluster-abcdefghijkl.eu-west-1.rds.amazonaws.com"
    master_user_secret_arn = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:example-app-nonprod-rds-master"
  }

  ecs_services = {
    api = {
      image          = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/example-app-api@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
      container_port = 8080
      public         = true
      env = {
        SPRING_DATASOURCE_URL = "jdbc:mysql://__RDS_ENDPOINT__:3306/__RDS_DB_NAME__"
        SPRING_MAIL_HOST      = "__SMTP_HOST__"
      }
      secret_arns = {
        SPRING_DATASOURCE_PASSWORD = "__RDS_MASTER_PASSWORD_SECRET_ARN__"
      }
    }
  }
}

run "runtime_tokens_are_resolved_for_microservices" {
  command = plan

  assert {
    condition     = output.ecs_services_final["api"].env["SPRING_DATASOURCE_URL"] == "jdbc:mysql://example-app-nonprod.cluster-abcdefghijkl.eu-west-1.rds.amazonaws.com:3306/app"
    error_message = "The RDS endpoint and DB name tokens should resolve inside ecs_services env values."
  }

  assert {
    condition     = output.ecs_services_final["api"].env["SPRING_MAIL_HOST"] == "email-smtp.eu-west-1.amazonaws.com"
    error_message = "The SMTP host token should resolve to the regional SES endpoint."
  }

  assert {
    condition     = output.ecs_services_final["api"].secret_arns["SPRING_DATASOURCE_PASSWORD"] == "arn:aws:secretsmanager:eu-west-1:123456789012:secret:example-app-nonprod-rds-master:password::"
    error_message = "The RDS password token should resolve to the managed secret password ARN suffix."
  }
}
