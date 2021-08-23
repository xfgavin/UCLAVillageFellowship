# Notification code for UCLA Village Fellowship

# Mechanisms:
1. publish google spreadsheet as html
2. use wget to pull html and use html2csv.py to parse html and save as two csv files: contact.csv and schedule.csv
3. send_noti_ucla.sh checks schedule.csv and see if there is an event 9 days ahead. If true, it will use contact.csv and schedule.csv to generate msg.html
4. use postfix to send msg.html

# Set up:
## postfix:
I used gmail smtp to setup postfix, please check postfix folder for example config

## notification scripts:
Please create a cron job to call send_noti_ucla.sh, I let the cron job run at 0:00 everyday.
The CC_list contains emails for:
1. present chairman
2. present praying coworker
3. present admin
So, please change accordingly when there is new group of coworks
Please also change adminemail to present admin's email.
