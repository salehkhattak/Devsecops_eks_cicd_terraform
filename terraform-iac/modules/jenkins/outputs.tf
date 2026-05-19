output "jenkins_public_ip" {
  description = "Public Elastic IP address of the Jenkins server"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:8080"
}

output "sonarqube_url" {
  description = "URL to access SonarQube"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:9000"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:9090"
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:3000"
}
