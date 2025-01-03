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

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling existing default NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing NodeJS 20"

useradd expense &>>$LOG_FILE_NAME
VALIDATE $? "Adding expense"

mkdir /app &>>$LOG_FILE_NAME
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading the backend"

cd /app
VALIDATE $? "Moving to app directory"

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "UnZipping the backend"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing the dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

#Prepare MySQL Schema
dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL Client"

mysql -h mysql.satharsuhel.fun -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Setting up the transactions schema and tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon Reload"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend"

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "Starting backend"
