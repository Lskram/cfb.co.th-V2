FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# เครื่องมือพื้นฐาน + curl + nc
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl netcat-traditional \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ติดตั้งไลบรารี Python
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# ติดตั้ง Tailwind CLI (x64) — ถ้าเป็น ARM64 เปลี่ยนลิงก์ดูโน้ตด้านล่าง
RUN curl -sSL -o /usr/local/bin/tailwindcss \
    https://github.com/tailwindlabs/tailwindcss/releases/latest/download/tailwindcss-linux-x64 \
 && chmod +x /usr/local/bin/tailwindcss

# คัดลอกโค้ดเข้า image
COPY . /app

# สร้าง entrypoint.sh (รอ DB -> build/watch Tailwind -> collectstatic/migrate -> gunicorn)
RUN printf "#!/bin/sh\n\
set -e\n\
until nc -z db 5432; do echo '⏳ waiting for db...'; sleep 1; done\n\
\n\
# Tailwind build/watch\n\
if [ \"\$DJANGO_DEBUG\" = \"1\" ] || [ \"\$DJANGO_DEBUG\" = \"True\" ] || [ \"\$DJANGO_DEBUG\" = \"true\" ]; then\n\
  echo \"🔧 Tailwind watch: assets/input.css -> static/css/tailwind.css\"\n\
  tailwindcss -i ./assets/input.css -o ./static/css/tailwind.css -c ./tailwind.config.js --watch &\n\
else\n\
  echo \"🏗️ Tailwind build (minify)\"\n\
  tailwindcss -i ./assets/input.css -o ./static/css/tailwind.css -c ./tailwind.config.js --minify\n\
fi\n\
\n\
python manage.py collectstatic --noinput\n\
python manage.py migrate --noinput\n\
exec gunicorn mysite.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 120\n" > /app/entrypoint.sh \
 && chmod +x /app/entrypoint.sh

EXPOSE 8000
CMD ["sh", "/app/entrypoint.sh"]
