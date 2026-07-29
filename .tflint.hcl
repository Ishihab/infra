tflint {
  required_version = "0.64.0"
}


config {
  format = "compact"
  plugin_dir = "~/.tflint.d/plugins"

  call_module_type = "all"
  force = false
  disabled_by_default = false

}



plugin "terraform" {
  enabled = true
  preset = "recommended"
}

plugin "aws" {
    enabled = true
    version = "0.48.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

