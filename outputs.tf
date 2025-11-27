output "mock_login_url" {
  value = "https://${aws_cognito_user_pool_domain.domain.domain}.auth.ap-southeast-2.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.client.id}&response_type=code&scope=email+openid+profile&redirect_uri=http://localhost:3000/callback"
}

output "mock_logout_url" {
  value = "https://${aws_cognito_user_pool_domain.domain.domain}.auth.ap-southeast-2.amazoncognito.com/logout?client_id=${aws_cognito_user_pool_client.client.id}&logout_uri=http://localhost:3000/callback"
}

output "ec2_static_ip" {
  value = aws_eip.static_ip.public_ip
}
