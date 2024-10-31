
### Prerequisites

1. [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) (v1.3+ is required).
2. [Install Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (optional, for authentication purposes).
3. [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (optional, for authentication purposes).
4. Create VNet in Azure with GatewaySubnet subnet
5. Create VPC in GCP 

### Assumptions

1. Required roles are assigned to respective principal (who will run the Terraform code) on GCP and Azure.
2. VPC in GCP and VNET in Azure is already created.
3. **GatewaySubnet** in Azure VNET is already created.
4. Traffic is allowed on Azure NSG for Virtual Network Gateway.
5. Traffic is allowed on GCP Firewall for VPN.

### Authentication

Use CLI or other methods to log in to GCP(gcloud) and Microsoft Azure(az cli).
You can use service principal and service account 

```bash
#authentication to gcp
gcloud auth application-default login

#authentication to azure
az login
```

### Configuration

Update `terraform.tfvars` file in the same directory as the Terraform configuration files with the following variables:

| Variable                | Description                             | Required | Default |
|-------------------------|-----------------------------------------|----------|---------|
| gcp_project_id          | The GCP project ID                      | Yes      |         |
| gcp_region              | The GCP region                          | Yes      |         |
| gcp_vpc_name            | The GCP VPC name                        | Yes      |         |
| gcp_router_name         | The GCP VPN router name                 | Yes      |         |
| gcp_bgp_asn             | The GCP VPC Router ASN                  | Yes      |  65534  |
| shared_secret           | The shared secret for the VPN connection| Yes      |         |
| azure_subscription_id   | The Azure subscription ID               | Yes      |         |
| azure_vnet_name         | The Azure VNET Name                     | Yes      |         |
| azure_region            | The Azure region                        | Yes      |         |
| azure_resource_group    | The Azure resource group                | Yes      |         |
| azure_bgp_asn           | The Azure BGP ASN                       | Yes      |  65515  |
| azure_vpn_sku           | The Azure VPN Sku                       | Yes      |  VpnGw1 |
| azure_vpn_allowed_az_skus           | The Azure VPN Availability Zones Allowed SKUs                       | No      |  ["VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ"] |

Replace the values as per your need.

### Usage

1. Initialize Terraform:

    ```bash
    terraform init
    ```

2. Plan and apply the Terraform configuration:

    ```bash
    terraform plan
    terraform apply
    ```

3. After the infrastructure is created, Terraform will output the GCP VPN Gateway IP, GCP VPN Tunnel Peer IPs, Azure VPN Gateway Public IPs, and Azure VPN Tunnel Peer IPs.

4. To clean up the resources, run:

    ```bash
    terraform destroy
    ```