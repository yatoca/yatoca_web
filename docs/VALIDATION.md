# Package validation notes

The generated portability package was checked in the sandbox as follows:

- every shell script under `scripts/` passed `bash -n`
- infrastructure JSON files passed `jq empty`
- Terraform files passed delimiter/balance sanity checks
- generated package was scanned for obvious access keys/secrets; no migration credential was included

The sandbox does not have a Terraform binary or network access to install providers, so a real `terraform fmt` / `terraform validate` could not be executed here.

Before using the Terraform configuration in a real AWS account, run locally:

```bash
cd infrastructure/terraform
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform plan
```

Review the plan carefully. For a new-account move, keep `attach_custom_certificate=false` and `enable_custom_domain=false` on the first apply.


## Validación local posterior (2026-09-12)

La configuración Terraform base fue inicializada y validada en macOS Apple Silicon usando Terraform 1.16.1 (`darwin_arm64`), AWS provider 6.64.0 y archive provider 2.8.1. `terraform validate` devolvió `Success! The configuration is valid.`

Después de aplicar cambios de infraestructura, volver a ejecutar:

```bash
cd infrastructure/terraform
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

No se considera probado un recovery completo hasta ejecutar `terraform apply` en una cuenta AWS de prueba/nueva y realizar smoke tests end-to-end.
