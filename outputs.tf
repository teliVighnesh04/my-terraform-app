output "web_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of Web instance"
}

output "web_ip22" {
  value       = aws_instance.web22.public_ip
  description = "Public IP of Web instance 22"
}

output "environment" {
  value       = var.environment
  description = "Environment name"
}
