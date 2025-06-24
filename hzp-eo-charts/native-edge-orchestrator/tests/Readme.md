# smoke tests
## Pre-requisites for local execution
### 1. Java / JDK - version 8 and above
- Download and install the latest version from [Community OpenJDK](https://openjdk.java.net/install/) (Linux) or [Red Hat OpenJDK](https://developers.redhat.com/products/openjdk/download) (Windows).
- Set environment variable JAVA_HOME to the path of the installed JDK.
- Verify the installation and also that the environment variable has been updated correctly by running the following commands.
```
java -version
# Windows
echo %JAVA_HOME%
# Linux and Git Bash
echo $JAVA_HOME
```
### 2. Maven
- Download and install the latest version from [Apache Maven](https://maven.apache.org/download.cgi).
- Add Maven bin folder location to the PATH variable.
- Verify the installation by running the following command:
```
mvn -version
```
## Execution of test scripts
### 1. Set the environment variables
You can create a `setenv.bat` or `.env` script.

Replace the IP address according to the required environment.
#### On Windows
```
@echo off

REM Local Environment Variables
set MESSAGING_URL=<NATS_URL>
set MESSAGING_STREAM_NAME=<NATS_STREAM_NAME>
set DATABASE_URL=<DATABASE_URL>
set DATABASE_USERNAME=<DATABASE_USERNAME>
set DATABASE_PASSWORD=<DATABASE_PASSWORD>
set FRU_CRU_SVC_BASE_URL=<FRU_CRU_SVC_API_ENDPOINT>
set INVENTORY_SVC_BASE_URL=<INVENTORY_SVC_API_ENDPOINT>
set ONBOARDING_SVC_BASE_URL=<ONBOARDING_SVC_API_ENDPOINT>
set JOB_SVC_BASE_URL=<JOB_SERVICE_API_ENDPOINT>
set EDGE_VAULT_URL=<EDGE_VAULT_API_ENDPOINT>
set SSH_USER_NAME=<SSH_USER_NAME>
set SSH_PASSWORD=<SSH_PASSWORD>
```

#### On Linux
```
# Local Environment Variables
export MESSAGING_URL=<NATS_URL>
export MESSAGING_STREAM_NAME=<NATS_STREAM_NAME>
export DATABASE_URL=<DATABASE_URL>
export DATABASE_USERNAME=<DATABASE_USERNAME>
export DATABASE_PASSWORD=<DATABASE_PASSWORD>
export FRU_CRU_SVC_BASE_URL=<FRU_CRU_SVC_API_ENDPOINT>
export INVENTORY_SVC_BASE_URL=<INVENTORY_SVC_API_ENDPOINT>
export ONBOARDING_SVC_BASE_URL=<ONBOARDING_SVC_API_ENDPOINT>
export JOB_SVC_BASE_URL=<JOB_SERVICE_API_ENDPOINT>
export EDGE_VAULT_URL=<EDGE_VAULT_URL>
export SSH_USER_NAME=<SSH_USER_NAME>
export SSH_PASSWORD=<SSH_PASSWORD>
```

### 2. mvn command to run the tests
```
mvn clean test -DsuiteXmlFile=test-suites/smoke.xml
```
