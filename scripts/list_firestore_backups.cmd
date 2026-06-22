@echo off
call "%~dp0gcloud.cmd" firestore backups schedules list --database="(default)" %*
