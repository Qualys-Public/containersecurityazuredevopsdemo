# ContainerSecurityAzureDevOpsDemo
An Azure DevOps Pipeline Demo to showcase scanning of images during build pipeline using Qualys Container Security (CS) before being pushed to the registry for deployment in Azure Web Apps and Scanning of Web Apps in QA slot using Qualys Web Application Scanning (WAS) before swapping it to production

## License
_**THIS SCRIPT IS PROVIDED TO YOU "AS IS."  TO THE EXTENT PERMITTED BY LAW, QUALYS HEREBY DISCLAIMS ALL WARRANTIES AND LIABILITY FOR THE PROVISION OR USE OF THIS SCRIPT.  IN NO EVENT SHALL THESE SCRIPTS BE DEEMED TO BE CLOUD SERVICES AS PROVIDED BY QUALYS**_

## Description
The aim of this repository is to build a solution which will help you understand how Qualys CS and WAS can be used to detect vulnerabilities in the Container Image and Web applications built from it.

## **Prerequisites:**
  1. [**An Azure Container Registry**](/examples/azurecontainerregistry.md)
  2. [**An Azure APP service with Containers**](/examples/azureappservice.md)
  3. A Qualys Subscription
 
## Usage
### Task 1: Use the Azure DevOps Demo Generator to provision the project to your Azure DevOps Org. Use the below GitHub link as source template
_https://raw.githubusercontent.com/mkhanal1/containersecurityazuredevopsdemo/master/containersecuritydemo.zip_

### Task 2: Import this repository to Azure GIT

### Task 3: Edit your pipeline variables in Variable Groups
The template file has these 9 variables.
  QUALYS_API_SERVER:
  QUALYS_PASSWORD:
  QUALYS_USERNAME:
  QUALYS_WAS_PROFILEID:
  SENSOR_ACTIVATION_ID:
  SENSOR_CUSTOMER_ID:
  WEBAPP_PASSWORD:
  WEBAPP_USERNAME:
  SENSOR_LOCATION:
