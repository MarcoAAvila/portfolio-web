"""
counter.py — Lambda: Visitor Counter
"""

import json
import os
import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME", "portfolio-visitor-counter")

# Client initialised outside the handler to benefit from Lambda execution
# context reuse across warm invocations.
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    """
    Increments the visitor counter and returns the updated value.

    Uses UpdateItem with ADD rather than GetItem + PutItem to guarantee
    atomicity: concurrent invocations cannot produce a lost update.
    """

    # CORS headers allow the browser to call the API from the portfolio domain.
    cors_headers = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "https://marcoaavila.dev",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
    }

    if event.get("requestContext", {}).get("http", {}).get("method") == "OPTIONS":
        return {"statusCode": 200, "headers": cors_headers, "body": ""}

    try:
        response = table.update_item(
            Key={"id": "visits"},
            UpdateExpression="ADD visit_count :increment",
            ExpressionAttributeValues={":increment": 1},
            ReturnValues="UPDATED_NEW",
        )

        new_count = int(response["Attributes"]["visit_count"])

        return {
            "statusCode": 200,
            "headers": cors_headers,
            "body": json.dumps({"visits": new_count}),
        }

    except ClientError as error:
        print(f"[ERROR] DynamoDB ClientError: {error.response['Error']['Message']}")
        return {
            "statusCode": 500,
            "headers": cors_headers,
            "body": json.dumps({"error": "Internal server error"}),
        }
    except Exception as error:
        print(f"[ERROR] Unexpected error: {str(error)}")
        return {
            "statusCode": 500,
            "headers": cors_headers,
            "body": json.dumps({"error": "Internal server error"}),
        }
