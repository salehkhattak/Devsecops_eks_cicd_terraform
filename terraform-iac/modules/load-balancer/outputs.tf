output "lb_controller_status" {
  description = "Helm release status of the AWS Load Balancer Controller"
  value       = helm_release.lb_controller.status
}

output "lb_controller_irsa_role_arn" {
  description = "IAM Role ARN used by the Load Balancer Controller (IRSA)"
  value       = module.lb_controller_irsa.iam_role_arn
}
