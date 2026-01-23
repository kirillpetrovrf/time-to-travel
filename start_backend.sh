#!/bin/bash

docker run -d \
  --name timetotravel_backend \
  --restart unless-stopped \
  -p 8080:8080 \
  --network timetotravel_network \
  -e DB_HOST=db \
  -e DB_PORT=5432 \
  -e DB_NAME=timetotravel \
  -e DB_USER=timetotravel \
  -e DB_PASSWORD=securE_PaSs2024! \
  -e TELEGRAM_BOT_TOKEN=8506333771:AAGmnk_JmIOHDXv649nlv_5NZiNqrt88RfE \
  -e JWT_SECRET=TimeToTravel_JWT_Secret_2026 \
  backend-backend:latest
