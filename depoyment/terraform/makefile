# Terraform Management Makefile
# Handles backend setup and environment deployments

.PHONY: help
help:
	@echo "Terraform Management Commands:"
	@echo ""
	@echo "Backend Management:"
	@echo "  make backend/init    - Initialize backend configuration"
	@echo "  make backend/plan    - Plan backend infrastructure"
	@echo "  make backend/apply   - Apply backend infrastructure"
	@echo "  make backend/destroy - Destroy backend infrastructure"
	@echo "  make backend/validate - Validate backend configuration"
	@echo ""
	@echo "Development Environment:"
	@echo "  make dev/init        - Initialize dev environment"
	@echo "  make dev/plan        - Plan dev infrastructure"
	@echo "  make dev/apply       - Apply dev infrastructure"
	@echo "  make dev/destroy     - Destroy dev infrastructure"
	@echo "  make dev/validate    - Validate dev configuration"
	@echo ""
	@echo "Staging Environment:"
	@echo "  make staging/init    - Initialize staging environment"
	@echo "  make staging/plan    - Plan staging infrastructure"
	@echo "  make staging/apply   - Apply staging infrastructure"
	@echo "  make staging/destroy - Destroy staging infrastructure"
	@echo "  make staging/validate - Validate staging configuration"
	@echo ""
	@echo "General Commands:"
	@echo "  make fmt             - Format all Terraform files"
	@echo "  make validate        - Validate all configurations"
	@echo "  make security        - Run security scan on all configs"
	@echo "  make clean           - Clean up temporary files"

# ==================================================================================== #
# BACKEND MANAGEMENT
# ==================================================================================== #

.PHONY: backend/init
backend/init:
	@echo " Initializing Terraform backend..."
	cd backend && terraform init
	@echo " Backend initialized successfully!"

.PHONY: backend/plan
backend/plan:
	@echo " Planning backend infrastructure..."
	cd backend && terraform plan -out=backend.tfplan
	@echo " Backend plan complete! Review the plan above."

.PHONY: backend/apply
backend/apply:
	@echo "  Applying backend infrastructure..."
	cd backend && terraform apply backend.tfplan
	@echo " Backend infrastructure deployed!"

.PHONY: backend/apply/auto
backend/apply/auto:
	@echo "  Auto-applying backend infrastructure..."
	cd backend && terraform apply -auto-approve
	@echo " Backend infrastructure deployed!"

.PHONY: backend/destroy
backend/destroy:
	@echo " Destroying backend infrastructure..."
	@echo "  WARNING: This will destroy the Terraform state bucket!"
	@echo "Press Ctrl+C to cancel, or any key to continue..."
	@read -r dummy
	cd backend && terraform destroy
	@echo " Backend infrastructure destroyed!"

.PHONY: backend/validate
backend/validate:
	@echo " Validating backend configuration..."
	cd backend && terraform validate
	@echo " Backend configuration is valid!"

# ==================================================================================== #
# DEVELOPMENT ENVIRONMENT
# ==================================================================================== #

.PHONY: dev/init
dev/init:
	@echo " Initializing dev environment..."
	cd environments/dev && terraform init
	@echo " Dev environment initialized!"

.PHONY: dev/plan
dev/plan:
	@echo " Planning dev infrastructure..."
	cd environments/dev && terraform plan -out=dev.tfplan
	@echo " Dev plan complete!"

.PHONY: dev/apply
dev/apply:
	@echo "  Applying dev infrastructure..."
	cd environments/dev && terraform apply dev.tfplan
	@echo " Dev infrastructure deployed!"

.PHONY: dev/apply/auto
dev/apply/auto:
	@echo "  Auto-applying dev infrastructure..."
	cd environments/dev && terraform apply -auto-approve
	@echo " Dev infrastructure deployed!"

.PHONY: dev/destroy
dev/destroy:
	@echo " Destroying dev infrastructure..."
	cd environments/dev && terraform destroy
	@echo " Dev infrastructure destroyed!"

.PHONY: dev/validate
dev/validate:
	@echo " Validating dev configuration..."
	cd environments/dev && terraform validate
	@echo " Dev configuration is valid!"

# ==================================================================================== #
# STAGING ENVIRONMENT
# ==================================================================================== #

.PHONY: staging/init
staging/init:
	@echo " Initializing staging environment..."
	cd environments/staging && terraform init
	@echo " Staging environment initialized!"

.PHONY: staging/plan
staging/plan:
	@echo " Planning staging infrastructure..."
	cd environments/staging && terraform plan -out=staging.tfplan
	@echo " Staging plan complete!"

.PHONY: staging/apply
staging/apply:
	@echo "  Applying staging infrastructure..."
	cd environments/staging && terraform apply staging.tfplan
	@echo " Staging infrastructure deployed!"

.PHONY: staging/apply/auto
staging/apply/auto:
	@echo "  Auto-applying staging infrastructure..."
	cd environments/staging && terraform apply -auto-approve
	@echo " Staging infrastructure deployed!"

.PHONY: staging/destroy
staging/destroy:
	@echo " Destroying staging infrastructure..."
	cd environments/staging && terraform destroy
	@echo " Staging infrastructure destroyed!"

.PHONY: staging/validate
staging/validate:
	@echo " Validating staging configuration..."
	cd environments/staging && terraform validate
	@echo " Staging configuration is valid!"

# ==================================================================================== #
# GENERAL COMMANDS
# ==================================================================================== #

.PHONY: fmt
fmt:
	@echo " Formatting all Terraform files..."
	terraform fmt -recursive .
	@echo " All Terraform files formatted!"

.PHONY: validate
validate: backend/validate dev/validate staging/validate
	@echo " All configurations validated!"

.PHONY: security
security:
	@echo " Running security scan on all configurations..."
	checkov --config-file ../../.checkov.yml --directory .
	@echo " Security scan complete!"

.PHONY: clean
clean:
	@echo " Cleaning up temporary files..."
	find . -name "*.tfplan" -delete
	find . -name ".terraform.lock.hcl" -delete
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@echo " Cleanup complete!"

# ==================================================================================== #
# WORKFLOW HELPERS
# ==================================================================================== #

.PHONY: backend/setup
backend/setup: backend/init backend/plan
	@echo " Backend is ready for deployment!"
	@echo "Run 'make backend/apply' to create the infrastructure."

.PHONY: dev/setup
dev/setup: dev/init dev/plan
	@echo " Dev environment is ready for deployment!"
	@echo "Run 'make dev/apply' to create the infrastructure."

.PHONY: staging/setup
staging/setup: staging/init staging/plan
	@echo " Staging environment is ready for deployment!"
	@echo "Run 'make staging/apply' to create the infrastructure."

.PHONY: init/all
init/all: backend/init dev/init staging/init
	@echo " All environments initialized!"

.PHONY: validate/all
validate/all: validate
	@echo " All environments validated!"
