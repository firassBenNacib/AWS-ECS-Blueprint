resource "aws_ecs_task_definition" "this" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions    = jsonencode([local.container_definition])

  dynamic "volume" {
    for_each = {
      for volume in var.task_volumes : volume.name => volume
    }
    content {
      configure_at_launch = false
      name                = volume.value.name
    }
  }
}
