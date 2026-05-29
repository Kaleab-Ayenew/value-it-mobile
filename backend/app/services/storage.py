import uuid

from app.config import settings


def _client():
    import boto3
    from botocore.client import Config

    return boto3.client(
        "s3",
        endpoint_url=settings.minio_endpoint,
        aws_access_key_id=settings.minio_access_key,
        aws_secret_access_key=settings.minio_secret_key,
        config=Config(signature_version="s3v4"),
        region_name="us-east-1",
    )


def upload_bytes(data: bytes, filename: str, content_type: str = "application/octet-stream") -> str:
    ext = filename.rsplit(".", 1)[-1] if "." in filename else "bin"
    key = f"photos/{uuid.uuid4()}.{ext}"
    client = _client()
    client.put_object(
        Bucket=settings.minio_bucket,
        Key=key,
        Body=data,
        ContentType=content_type,
    )
    return key


def public_url(key: str) -> str:
    return f"{settings.minio_public_url.rstrip('/')}/{key}"
