FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY minihole ./minihole
COPY main.py ./main.py
COPY data ./data
EXPOSE 8000/tcp 5353/udp 5353/tcp
CMD ["python", "main.py"]
