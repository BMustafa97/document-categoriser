def lambda_handler(event, context):
    print('Hello World from test.py')
    
    return {
        'statusCode': 200,
        'body': 'Hello World from test.py'
    }

if __name__ == "__main__":
    lambda_handler(None, None)