ui = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

storage "file" {
  path = "/vault/data"
}

seal "awskms" {
  region = "${region}"
  kms_key_id = "${kms_key_arn}"
}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "http://127.0.0.1:8201"
disable_mlock = true
