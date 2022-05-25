# terraform-azure-private-dns-resolver-azapi

This repo contains code that helps you implement Microsoft's new Azure Private DNS Resolver feature entirely in Terraform by leveraging the new AzAPI provider.

## Inputs

The following inputs need to be provided to the code.

| Variable | Description |
| ------ | ------ |
| cl_id | App Registration Client ID |
| cl_sec | App Registration Client Secret |
| sub_id | Subscription ID |
| ten_id | Tenant ID |

## How to use the code (secrets variable input)

- Clone the repo to your local IDE.
- Create a "terraform.tfvars" file in the local cloned repo folder with the below contents.

```hcl
sub_id = "00000000-0000-0000-0000-000000000000"
ten_id = "00000000-0000-0000-0000-000000000000"
```

- Run "Terraform plan -var 'cl_id=`your app client id`' -var 'cl_sec=`your client secret`' -out tfplan"
- Run "Terraform apply tfplan"

## How to use the code (secrets variable file)

- Clone the repo to your local IDE.
- Create a "terraform.tfvars" file in the local cloned repo folder with the below contents.
```hcl
sub_id = "00000000-0000-0000-0000-000000000000"
cl_id  = "00000000-0000-0000-0000-000000000000"
cl_sec = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
ten_id = "00000000-0000-0000-0000-000000000000"
```
- Run "Terraform Plan"
- Run "Terraform Apply"

## Gotchas!

Because the AzAPI was recently announced, there are some nuances to using the provider that will hopefully fixed in following iterations. Some of the gotchas I've encountered are below:
- It took a while to find the correct Parent ID. You'd assume that the parent for the RuleSet would be the DNS Resolver given that is where you actually configure it, but its actually the Resource Group. Go figure!
- If your initial setup fails for any reason which mine did while I was trying to figure out the parent for the RuleSet, you have to destroy all the resources and rebuild because although the preview API exists for the DNS resolver the current "Microsoft.Network/virtualNetworks/subnets@2021-08-01" API doesn't accept the "Microsoft.Network/dnsResolvers" value yet.
- If you try to add additional resources or modify any existing resources in the Terraform code post the first apply (for example, a new forwarding rule), your apply will error out. The preview feature delegates the inbound and outbound subnets to the "Microsoft.Networks" provider but the terraform state does not understand and therefore does not store this change. It exists only in Azure (until the AzAPI provider catches up obviously with future udpates) so anything you modify post the initial apply will cause the terrform run to try and remove these delegations. 
- Resource dependency when running "Terraform Destroy". For some reason the destroy operation does not understand dependencies and I have had to manually delete the RuleSet and Resolver before the Resource Group can be automatically deleted by the destroy operation.
