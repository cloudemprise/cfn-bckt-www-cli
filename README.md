# cfn-www-cicd-cli

> A CI/CD pipeline of a secure HTTPS static website fronted by a CDN.

A low-latency, reliable and secure static cloud website appliance; accompanied by an automated software deployment mechanism; orchestrated in Cloudformation via the AWS command line interface.

[![Linux](https://img.shields.io/badge/OS-Linux-blue?logo=linux)](https://github.com/cloudemprise/cfn-ovpn-cli)
![Bash](https://img.shields.io/badge/Bash->=v4.0-green?logo=GNU%20bash)
[![jq](https://img.shields.io/badge/jq-v1.6-green.svg)](https://github.com/stedolan/jq)
[![awscli](https://img.shields.io/badge/awscli->=v2.0-green.svg)](https://github.com/aws/aws-cli)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)


## Prerequisites

- aws account.
- route 53 hosted zone.
- domain certificate.
- git version control repository.
- jq version 1.6
- awscli version 2
- bash > version 4

Table of Contents
=================

- [Introduction](#introduction)
- [Topic 1](#topic-1)
- [Topic 2](#topic-2)
- [Conclusion](#conclusion)

## Introduction

**cfn-www-cicd-cli** is a shell script that creates a cloud-based static website application that includes a CI/CD pipeline. This provides for a secure, low-latency personal website solution. The AWS Command Line Interface (AWS CLI) is used to provision and configure various AWS Resources through an assortment of API calls and AWS Cloudformation templates.

##### An overview of the program structure:

At the start, the shell script requests an assortment of parameters from the script caller pertaining to the project prerequisites and other program environment variables. Before any further processing or API calls are made some rudimentary error checking and validation is performed on the project environment to pick up on any silly mistakes or obvious errors.

The script then builds an assortment of IAM control access policies. These artefacts and other significant project documents are then uploaded into cloud storage as reference material for further operational activities as well as an archive of record.

The cloud infrastructure provisioning process can now commence and takes the form of an AWS CloudFormation stack creation procedure.

## Topic 1

**cfn-www-cicd-cli** is a shell script that creates a cloud-based Static Website application together with a CI/CD pipeline, that comprises an Amazon Route 53 Custom Domain, an Amazon S3 bucket configured for website hosting and an Amazon CloudFront distribution together with a Public X.509 Certificate. AWS CodePipeline in conjuction with the AWS CodeCommit version control service is used to automate the deployment of a software release process. This provides for a secure, highly available, fault toleranct, cost effective, low-latency, website hosting solution in the cloud. The AWS Command Line Interface (AWS CLI) is used to provision and configure various AWS Resources through an assortment of API calls and AWS Cloudformation templates.



## Topic 2

Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.


## Conclusion

Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.