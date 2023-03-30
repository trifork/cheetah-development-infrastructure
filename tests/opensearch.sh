#!/bin/bash

# Only start opensearch
docker compose --profile=oauth --profile=opensearch up --quiet-pull --force-recreate 

# Get token
curl -X 'POST' \
  'http://localhost:1752/oauth2/token' \
  -H 'accept: */*' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials&scope=&client_id=123&client_secret='

# Test token
curl -X GET "http://localhost:9229/_cat/indices" -H  "accept: application/json" -H  "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjBERTI4RTU4ODI3MTA0RTdBQ0JCNDM4QzE5QTQzNjgzMjc1RjdDRjUifQ.eyJzdWIiOiIxMjMiLCJ0eXAiOiJCZWFyZXIiLCJqdGkiOiJhYjA3NzE0Zi1jMTc1LTQ2ODEtOGM0NC04MDZhNzg3MjU4NWQiLCJ2ZXIiOiIxLjAiLCJhcHB0eXBlIjoiQ29uZmlkZW50aWFsIiwiYXV0aF90aW1lIjoiMjAyMy0wMy0zMFQxMDo1MDozMS45MTM2Mzk2KzAwOjAwIiwiYXBwaWQiOiJ1cm46Y2hlZXRhaDpjbGllbnQiLCJuYmYiOjE2ODAxNzM0MzEsImV4cCI6MTY4MDE3NzAzMSwiaWF0IjoxNjgwMTczNDMxLCJpc3MiOiIxMjMiLCJhdWQiOiJodHRwczovL2NoZWV0YWhvYXV0aHNpbXVsYXRvcjoxNzUyL29hdXRoMi90b2tlbiIsImF1dGhtZXRob2QiOiJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL3dzLzIwMDgvMDYvaWRlbnRpdHkvYXV0aGVudGljYXRpb25tZXRob2QvdGxzY2xpZW50IiwidG9waWNzIjoiKl9hbGwiLCJvc3JvbGVzIjoiZGVmYXVsdF9zZXJ2aWNlIn0.BHzYIaAfGUFHUSSOqZgQILBnlzEK82d4MK996rgTVeRt5sJUX8YuqU2f2DIN3JDGMeM-j0wcNb-gjyrMDpiZxXG1WYG1oPIrBofpLb5TohVLQbVSzL3FyzEPBOq2QTKmbVCHY98aPVS9la6jJGP_63vuLeq_f5Y2FFHtiy-i6ApFOqHgfkblTPb-HeyeHnU52Exk139wKtYLGyw4ITZmFlZHc9EsJ2fOif2NJ2Ysw-82BWpNQS9FpL5Grb57AQ04U1gqBgTLj55BNHztBjBuVvFfJzC9Md3svlpROfIYfZPEffdz7LbH_AMW10U3jyvZFGW8AlgKD9L4m6-8doigCg"

# Test basic auth
curl  -X GET "http://admin:admin@localhost:9229/_cat/indices" 
