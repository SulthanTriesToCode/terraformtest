output "db_public_hostname" {
    value = aws_instance.db.public_dns
}

output "app_public_hostname" {
    value = aws_instance.app.public_dns
}
