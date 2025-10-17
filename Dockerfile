FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN apt-get update && apt-get install -y --no-install-recommends build-essential curl netcat-traditional && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY . /app
RUN printf "#!/bin/sh\nset -e\nuntil nc -z db 5432; do echo '⏳ waiting for db...'; sleep 1; done\npython manage.py collectstatic --noinput\npython manage.py migrate --noinput\nexec gunicorn mysite.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 120\n" > /app/entrypoint.sh && chmod +x /app/entrypoint.sh
EXPOSE 8000
CMD ["sh", "/app/entrypoint.sh"]
