#!/bin/bash

# Configuration
API_URL="http://127.0.0.1:3000"
AUTH_TOKEN="dev-token-123"

# Color formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Running curl tests for Flights API"
echo "==================================="

# Test 1: Health Check (No auth required)
echo -e "\n${GREEN}Test 1: Health Check${NC}"
curl -s "${API_URL}/health" | jq '.'

# Test 2: GET flight by ID (with auth)
echo -e "\n${GREEN}Test 2: GET flight by ID${NC}"
curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" "${API_URL}/flight/1" | jq '.'

# TEST 22
echo -e "\n${GREEN}Test 22: GET flight by ID${NC}"
status_code=$(curl -s -o /tmp/response.txt -w "%{http_code}" -H "Authorization: Bearer ${AUTH_TOKEN}" "${API_URL}/flight/1")
echo "Status code: $status_code"
echo "Response body:"
cat /tmp/response.txt
echo ""
if cat /tmp/response.txt | jq '.' &>/dev/null; then
cat /tmp/response.txt | jq '.'
fi

# Test 3: Check if flight was delayed
echo -e "\n${GREEN}Test 3: Check if flight was delayed${NC}"
curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" "${API_URL}/check-delay/1" | jq '.'

# Test 4: Get average departure delay by airline
echo -e "\n${GREEN}Test 4: Get average departure delay by airline${NC}"
curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" "${API_URL}/avg-dep-delay/AA" | jq '.'

# Test 5: Get top destinations
echo -e "\n${GREEN}Test 5: Get top 5 destinations${NC}"
curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" "${API_URL}/top-destinations/5" | jq '.'

# Test 41: Get average departure delay by airline
echo -e "\n${GREEN}Test 41: Get average departure delay by airline${NC}"
curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" "${API_URL}/avg-dep-delay/AA" | jq '.'


 curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" "${API_URL}/flight/13" | jq '.'
 
# Test 7: Update flight details (PUT)
echo -e "\n${GREEN}Test 7: Update flight details (PUT)${NC}"
curl -v -X PUT "${API_URL}/flights/13" -H "Authorization: Bearer ${AUTH_TOKEN}" \
-H "Content-Type: application/json" \
-d '{
    "year": "2010",
    "carrier": "AA"
  }' 


echo -e "\n${GREEN}Verify flight data"
curl -s -H "Authorization: Bearer ${AUTH_TOKEN}" "${API_URL}/flight/13" | jq '.'




# Test 8: Delete flight
echo -e "\n${GREEN}Test 8: Delete flight${NC}"
curl -s -X DELETE -H "Authorization: Bearer ${AUTH_TOKEN}" "${API_URL}/1" | jq '.'

