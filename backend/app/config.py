from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql://valueit:valueit@localhost:5433/valueit"
    secret_key: str = "dev-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24
    upload_dir: str = "uploads"

    minio_endpoint: str = "http://localhost:9000"
    minio_access_key: str = "minioadmin"
    minio_secret_key: str = "minioadmin"
    minio_bucket: str = "valueit"
    minio_public_url: str = "http://localhost:9000/valueit"

    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = "noreply@valueit.local"

    class Config:
        env_file = ".env"


settings = Settings()
