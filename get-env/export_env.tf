resource "null_resource" "example_env" {
  triggers = {
    always_recreate = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "/bin/sh ${path.module}/scripts/env.sh > output.txt"
  }
}

data "local_file" "output" {
  depends_on = [null_resource.example_env]
  filename   = "${path.module}/output.txt"
}

output "script_output" {
  value = data.local_file.output.content
}
