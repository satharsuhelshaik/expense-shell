#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOG_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}


CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR: You must be ROOT USER and needed the sudo access to execute this script"
        exit 1
    fi    
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing nginx server"

systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? "Enabling nginx server"

systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? "Starting nginx server"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE_NAME
VALIDATE $? "Removing existing content that web server/web site is having"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading latest Frondend files"


cd /usr/share/nginx/html &>>$LOG_FILE_NAME
rm -rf /usr/share/nginx/html/*
VALIDATE $? "Moving to HTML directory"

unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
VALIDATE $? "UnZipping the frontend code"

systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? "Restarting frontend/ngnix"