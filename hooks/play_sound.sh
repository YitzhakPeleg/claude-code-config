#!/bin/bash

# Hook: Play a sound when user submits a prompt
# Uses terminal bell which works in most terminal emulators

# Send terminal bell character directly to the terminal
# The bell character (\a or \007) triggers an audible/visual alert
sleep 0.01
printf '\a'

# Alternative: Send multiple bells for a more noticeable effect
# Uncomment the line below if you want a double beep:
# sleep 0.25
# printf '\a'

# Exit successfully (don't block the prompt submission)
exit 0
