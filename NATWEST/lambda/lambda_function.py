import json

def lambda_handler(event, context):
    print("S3 Event Triggered:")
    print(json.dumps(event))
    return {
        'statusCode': 200,
        'body': json.dumps('S3 event logged to CloudWatch')
    }
