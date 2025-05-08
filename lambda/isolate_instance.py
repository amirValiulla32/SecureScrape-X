import boto3
import json
import logging
import os

# Mapping of GuardDuty threat types to human-readable explanations
GUARDDUTY_TYPE_MAP = {
    "UnauthorizedAccess:EC2/SSHBruteForce": "This indicates a brute-force SSH login attempt to an EC2 instance. This might be a prelude to unauthorized access.",
    "Recon:EC2/PortProbeUnprotectedPort": "An external actor scanned the instance for open ports. It may indicate reconnaissance activity.",
    "CryptoCurrency:EC2/BitcoinTool.B!DNS": "This instance is likely running unauthorized cryptocurrency mining software. The instance may be compromised.",
    "Trojan:EC2/BlackholeTraffic!DNS": "Detected communication with a known trojan server. This is a strong indicator of compromise.",
    "Impact:EC2/DenialOfService": "This instance may be involved in a denial-of-service attack, either as a target or an origin.",
    "Persistence:EC2/MetaDataAccess": "Detected suspicious access to EC2 metadata service, possibly to steal IAM credentials for persistence."
}

def query_bedrock(prompt: str) -> str:
    client = boto3.client("bedrock-runtime", region_name="us-east-1")

    body = {
        "prompt": f"\n\nHuman: {prompt}\n\nAssistant:",
        "max_tokens_to_sample": 300,
        "temperature": 0.5,
        "top_k": 250,
        "top_p": 1.0,
        "stop_sequences": ["\n\n"]
    }

    response = client.invoke_model(
        body=json.dumps(body),
        modelId="anthropic.claude-v2",
        contentType="application/json",
        accept="application/json"
    )

    result = json.loads(response['body'].read())
    return result['completion']

# Setup structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))
    
    env = os.getenv("ENVIRONMENT", "dev")

    if env != "prod":
        logger.info("[DEV MODE] Skipping EC2 shutdown.")
        return {
            'statusCode': 200,
            'body': f'[DEV MODE] Received event but did not take destructive action: {json.dumps(event)}'
        }

    # Attempt to describe the threat
    raw_type = event.get('detail', {}).get('type', 'Unknown threat')
    explanation = GUARDDUTY_TYPE_MAP.get(raw_type, f"Analyze this GuardDuty finding: {raw_type}")
    logger.info("Prompt sent to Bedrock: %s", explanation)

    try:
        ai_analysis = query_bedrock(explanation)
        logger.info("AI Threat Summary: %s", ai_analysis)
    except Exception as e:
        logger.warning("Bedrock query failed: %s", str(e))
        ai_analysis = "Could not fetch AI summary."

    # Extract EC2 instance ID
    try:
        instance_id = event['detail']['resource']['instanceDetails']['instanceId']
        logger.info("Target instance ID: %s", instance_id)
    except KeyError:
        logger.error("Instance ID not found in event.")
        return {
            'statusCode': 400,
            'body': 'Instance ID not found in event.'
        }

    # Attempt to stop the EC2 instance
    ec2 = boto3.client('ec2')
    try:
        ec2.stop_instances(InstanceIds=[instance_id])
        logger.info("Successfully sent stop command to EC2 instance: %s", instance_id)
        return {
            'statusCode': 200,
            'body': f'EC2 instance {instance_id} has been stopped. AI Summary: {ai_analysis}'
        }
    except Exception as e:
        logger.exception("Failed to stop EC2 instance:")
        return {
            'statusCode': 500,
            'body': f'Failed to stop instance: {str(e)}'
        }

