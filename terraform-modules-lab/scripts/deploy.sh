#!/bin/bash

# Terraform Deployment Script for TaskMaster Application
# This script automates the deployment process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="taskmaster"
TERRAFORM_DIR="."

# Functions
print_step() {
    echo -e "\n${BLUE}==== $1 ====${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking Prerequisites"
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure'."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Initialize Terraform
init_terraform() {
    print_step "Initializing Terraform"
    
    cd "$TERRAFORM_DIR"
    
    if terraform init; then
        print_success "Terraform initialized successfully"
    else
        print_error "Terraform initialization failed"
        exit 1
    fi
}

# Validate Terraform configuration
validate_terraform() {
    print_step "Validating Terraform Configuration"
    
    if terraform validate; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform configuration validation failed"
        exit 1
    fi
}

# Plan Terraform deployment
plan_terraform() {
    print_step "Planning Terraform Deployment"
    
    echo -e "${YELLOW}This will show you what resources will be created...${NC}"
    
    if terraform plan -out=tfplan; then
        print_success "Terraform plan completed successfully"
        echo -e "\n${YELLOW}Review the plan above. Do you want to continue? (y/N)${NC}"
        read -r response
        if [[ "$response" != "y" && "$response" != "Y" ]]; then
            print_warning "Deployment cancelled by user"
            rm -f tfplan
            exit 0
        fi
    else
        print_error "Terraform planning failed"
        exit 1
    fi
}

# Apply Terraform configuration
apply_terraform() {
    print_step "Applying Terraform Configuration"
    
    if terraform apply tfplan; then
        print_success "Terraform deployment completed successfully"
        rm -f tfplan
    else
        print_error "Terraform deployment failed"
        rm -f tfplan
        exit 1
    fi
}

# Show deployment outputs
show_outputs() {
    print_step "Deployment Information"
    
    echo -e "\n${GREEN}🎉 Deployment Successful!${NC}"
    echo -e "\n${BLUE}Application Details:${NC}"
    
    # Get outputs
    LOAD_BALANCER_URL=$(terraform output -raw load_balancer_url)
    S3_BUCKET_NAME=$(terraform output -raw s3_bucket_name)
    INSTANCE_IPS=$(terraform output -json instance_public_ips | jq -r '.[]')
    
    echo -e "  📱 Application URL: ${GREEN}$LOAD_BALANCER_URL${NC}"
    echo -e "  🗄️  S3 Bucket: ${GREEN}$S3_BUCKET_NAME${NC}"
    echo -e "  🖥️  Instance IPs:"
    
    for ip in $INSTANCE_IPS; do
        echo -e "     • $ip"
    done
    
    echo -e "\n${YELLOW}Note: It may take a few minutes for the application to be fully available.${NC}"
    echo -e "${YELLOW}The load balancer health checks need time to pass before traffic is routed.${NC}"
    
    # Test application availability
    echo -e "\n${BLUE}Testing Application...${NC}"
    for i in {1..5}; do
        if curl -s -o /dev/null -w "%{http_code}" "$LOAD_BALANCER_URL" | grep -q "200"; then
            print_success "Application is responding!"
            break
        else
            echo -e "  Attempt $i/5: Application not ready yet, waiting 30 seconds..."
            sleep 30
        fi
    done
}

# Cleanup function
cleanup() {
    print_step "Cleaning Up Terraform Resources"
    
    echo -e "${YELLOW}This will destroy ALL resources created by this Terraform configuration.${NC}"
    echo -e "${RED}This action cannot be undone!${NC}"
    echo -e "\n${YELLOW}Are you sure you want to destroy all resources? (y/N)${NC}"
    read -r response
    
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        print_step "Destroying Resources"
        if terraform destroy -auto-approve; then
            print_success "All resources have been destroyed"
        else
            print_error "Failed to destroy some resources"
            exit 1
        fi
    else
        print_warning "Cleanup cancelled"
    fi
}

# Show help
show_help() {
    echo -e "\n${BLUE}TaskMaster Terraform Deployment Script${NC}"
    echo -e "\nUsage: $0 [COMMAND]"
    echo -e "\nCommands:"
    echo -e "  deploy    - Deploy the complete infrastructure (default)"
    echo -e "  plan      - Show what will be deployed without applying"
    echo -e "  destroy   - Destroy all deployed resources"
    echo -e "  validate  - Validate Terraform configuration"
    echo -e "  outputs   - Show deployment outputs"
    echo -e "  help      - Show this help message"
    echo -e "\nExamples:"
    echo -e "  $0 deploy     # Deploy everything"
    echo -e "  $0 plan       # Preview changes"
    echo -e "  $0 destroy    # Clean up resources"
}

# Main deployment function
deploy() {
    print_step "Starting TaskMaster Deployment"
    check_prerequisites
    init_terraform
    validate_terraform
    plan_terraform
    apply_terraform
    show_outputs
}

# Main script logic
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    plan)
        check_prerequisites
        init_terraform
        validate_terraform
        terraform plan
        ;;
    destroy|cleanup)
        cleanup
        ;;
    validate)
        validate_terraform
        ;;
    outputs)
        if [[ -f "terraform.tfstate" ]]; then
            show_outputs
        else
            print_error "No terraform state found. Deploy first."
            exit 1
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac