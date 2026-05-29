import asyncio

import aiosmtplib
from email.message import EmailMessage

from app.config import settings


async def send_report_email(to_email: str, subject: str, body: str, pdf_bytes: bytes, filename: str) -> bool:
    if not settings.smtp_host:
        return False
    msg = EmailMessage()
    msg["From"] = settings.smtp_from
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.set_content(body)
    msg.add_attachment(pdf_bytes, maintype="application", subtype="pdf", filename=filename)
    await aiosmtplib.send(
        msg,
        hostname=settings.smtp_host,
        port=settings.smtp_port,
        username=settings.smtp_user or None,
        password=settings.smtp_password or None,
        start_tls=True,
    )
    return True


def send_report_email_sync(*args, **kwargs) -> bool:
    return asyncio.run(send_report_email(*args, **kwargs))
