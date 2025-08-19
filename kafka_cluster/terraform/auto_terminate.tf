# Safety net: self-terminates all 3 kafka_node instances ~2 hours after
# creation so a forgotten cluster doesn't rack up cost. One-time EventBridge
# Scheduler rule covering all 3 nodes at once, no Lambda involved:
#
#   time_offset.self_terminate_at        (now + 2h, pinned to all 3 instance
#                                          ids via `triggers` so re-applies
#                                          don't keep pushing the deadline out)
#   data.aws_caller_identity.current     (account id, for the IAM resource ARNs)
#           │
#           ▼
#   aws_iam_role.scheduler_terminate     (trust: scheduler.amazonaws.com)
#     └─ aws_iam_role_policy             (ec2:TerminateInstances, scoped to
#                                          node1/node2/node3's ARNs only)
#           │
#           ▼
#   aws_scheduler_schedule.self_terminate
#     ├─ schedule_expression    = at(<time_offset>)   — fires once, UTC
#     ├─ target                 = EC2 TerminateInstances (AWS SDK universal
#     │                            target) — one call, InstanceIds = all 3
#     └─ action_after_completion = DELETE — the schedule removes itself from
#        the console once it fires, so one-time schedules don't pile up.
#        Execution history stays visible in CloudTrail / Scheduler's own
#        invocation log regardless of the schedule resource being deleted.
#
# One shared schedule (rather than one per node) because all 3 nodes are
# created together and TerminateInstances accepts multiple instance IDs in
# a single call — no need for 3x the IAM roles/policies/schedules.

resource "time_offset" "self_terminate_at" {
  offset_hours = 2

  triggers = {
    instance_ids = join(",", [
      aws_instance.kafka_node1.id,
      aws_instance.kafka_node2.id,
      aws_instance.kafka_node3.id,
    ])
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "scheduler_terminate" {
  name = "kafka-cluster-scheduler-terminate-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
      }
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_terminate" {
  name = "terminate-kafka-cluster-nodes"
  role = aws_iam_role.scheduler_terminate.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "ec2:TerminateInstances"
      Resource = [
        "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.kafka_node1.id}",
        "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.kafka_node2.id}",
        "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.kafka_node3.id}",
      ]
    }]
  })
}

resource "aws_scheduler_schedule" "self_terminate" {
  name = "kafka-cluster-self-terminate"

  flexible_time_window {
    mode = "OFF"
  }

  # AWS `at()` expressions take no timezone suffix; default schedule
  # timezone is UTC.
  schedule_expression = "at(${formatdate("YYYY-MM-DD'T'hh:mm:ss", time_offset.self_terminate_at.rfc3339)})"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:terminateInstances"
    role_arn = aws_iam_role.scheduler_terminate.arn

    input = jsonencode({
      InstanceIds = [
        aws_instance.kafka_node1.id,
        aws_instance.kafka_node2.id,
        aws_instance.kafka_node3.id,
      ]
    })
  }

  action_after_completion = "DELETE"
}
