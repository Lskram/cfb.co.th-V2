#!/bin/sh
set -e

# Wait for Postgres
while ! nc -z db 5432; do
  echo "waiting for db..."
  sleep 1
done

python manage.py collectstatic --noinput
python manage.py migrate --noinput

exec gunicorn mysite.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 120
