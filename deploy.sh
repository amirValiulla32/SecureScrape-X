#!/bin/bash
echo "Zipping Lambda code..."
zip -j lambda/lambda.zip lambda/isolate_instance.py

echo "Applying Terraform..."
terraform apply -auto-approve

