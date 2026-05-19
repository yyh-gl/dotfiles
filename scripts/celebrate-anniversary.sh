#!/bin/bash

# Get today's date in seconds since epoch
TODAY_SEC=$(date +%s)

# Define anniversary date (November 9, 2024)
ANNIVERSARY="2024-11-09"
ANNIVERSARY_SEC=$(date -d "$ANNIVERSARY" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$ANNIVERSARY" +%s)

# Calculate next half anniversary
HALF_YEAR_LATER=$(date -d "$ANNIVERSARY +6 months" +%Y-%m-%d 2>/dev/null || date -j -v+6m -f "%Y-%m-%d" "$ANNIVERSARY" +%Y-%m-%d)
CURRENT_YEAR=$(date +%Y)
NEXT_YEAR=$((CURRENT_YEAR + 1))

# Extract month and day from half anniversary
HALF_MONTH=$(echo $HALF_YEAR_LATER | cut -d'-' -f2)
HALF_DAY=$(echo $HALF_YEAR_LATER | cut -d'-' -f3)

# Calculate next half anniversary date
NEXT_HALF_ANNIVERSARY="${CURRENT_YEAR}-${HALF_MONTH}-${HALF_DAY}"
NEXT_HALF_ANNIVERSARY_SEC=$(date -d "$NEXT_HALF_ANNIVERSARY" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$NEXT_HALF_ANNIVERSARY" +%s)

# If next half anniversary is in the past, use next year
if [ $NEXT_HALF_ANNIVERSARY_SEC -lt $TODAY_SEC ]; then
    NEXT_HALF_ANNIVERSARY="${NEXT_YEAR}-${HALF_MONTH}-${HALF_DAY}"
    NEXT_HALF_ANNIVERSARY_SEC=$(date -d "$NEXT_HALF_ANNIVERSARY" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$NEXT_HALF_ANNIVERSARY" +%s)
fi

# Calculate next year anniversary
ANNIVERSARY_MONTH=$(echo $ANNIVERSARY | cut -d'-' -f2)
ANNIVERSARY_DAY=$(echo $ANNIVERSARY | cut -d'-' -f3)
NEXT_YEAR_ANNIVERSARY="${CURRENT_YEAR}-${ANNIVERSARY_MONTH}-${ANNIVERSARY_DAY}"
NEXT_YEAR_ANNIVERSARY_SEC=$(date -d "$NEXT_YEAR_ANNIVERSARY" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$NEXT_YEAR_ANNIVERSARY" +%s)

# If next year anniversary is in the past, use next year
if [ $NEXT_YEAR_ANNIVERSARY_SEC -lt $TODAY_SEC ]; then
    NEXT_YEAR_ANNIVERSARY="${NEXT_YEAR}-${ANNIVERSARY_MONTH}-${ANNIVERSARY_DAY}"
    NEXT_YEAR_ANNIVERSARY_SEC=$(date -d "$NEXT_YEAR_ANNIVERSARY" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$NEXT_YEAR_ANNIVERSARY" +%s)
fi

# Calculate days
SECONDS_PER_DAY=86400
PASSED_DAYS=$(( (TODAY_SEC - ANNIVERSARY_SEC) / SECONDS_PER_DAY ))
HALF_DIFF=$(( (NEXT_HALF_ANNIVERSARY_SEC - TODAY_SEC) / SECONDS_PER_DAY ))
YEAR_DIFF=$(( (NEXT_YEAR_ANNIVERSARY_SEC - TODAY_SEC) / SECONDS_PER_DAY ))

# Print results
echo ""
echo "<< Important Day >>"
echo "Passed Days -> ${PASSED_DAYS} days passed"
echo "Next Half Important Day -> ${HALF_DIFF} days left"
echo "Next Year Important Day -> ${YEAR_DIFF} days left"
