#!/bin/bash

set -e

ACCOUNT_ID=
USERNAME=
PASSWORD=
VARFILE=
WORKSPACE_NAME=
IGW=
NOCMK=
PLAN=
FRONT_END_ACCESS=
FRONT_END_PL_SUBNET_IDS=
FROND_END_PL_SOURCE_SUBNET_IDS=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -a|--account_id)
      ACCOUNT_ID="$2"
      shift # past argument
      shift # past value
      ;;
    -u|--username)
      USERNAME="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--password)
      PASSWORD="$2"
      shift # past argument
      shift # past value
      ;;
    -vf|--var-file)
      VARFILE="$2"
      shift # past argument
      shift # past value
      ;;
    -w|--workspace)
      WORKSPACE_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -igw)
      IGW=true
      shift # past argument
      ;;
    -nocmk|--no_customer_managed_keys)
      NOCMK="$2"
      shift # past argument
      shift # past value
      ;;
    -plan)
      PLAN=true
      shift # past argument
      ;;
    -fea|--front_end_access)
      FRONT_END_ACCESS="$2"
      shift # past argument
      shift # past value
      ;;
    -feplsids|--front_end_pl_subnet_ids)
      FRONT_END_PL_SUBNET_IDS="$2"
      shift # past argument
      shift # past value
      ;;
    -feplsrcsids|--front_end_pl_source_subnet_ids)
      FROND_END_PL_SOURCE_SUBNET_IDS="$2"
      shift # past argument
      shift # past value
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -n "$PLAN" ] && [ "$PLAN" = "true" ]; then
TFAPPLY=(terraform plan)
else
TFAPPLY=(terraform apply -auto-approve) # terraform apply initial command
fi
if [ -n "$VARFILE" ]; then
TFAPPLY+=( -var-file=$VARFILE)
fi
if [ -n "$ACCOUNT_ID" ]; then
TFAPPLY+=( -var="databricks_account_id=$ACCOUNT_ID")
fi
if [ -n "$USERNAME" ]; then
TFAPPLY+=( -var="databricks_account_username=$USERNAME")
fi
if [ -n "$PASSWORD" ]; then
TFAPPLY+=( -var="databricks_account_username=$PASSWORD")
fi
if [ -n "$WORKSPACE_NAME" ]; then
TFAPPLY+=( -var="databricks_workspace_name=$WORKSPACE_NAME")
fi
if [ -n "$IGW" ] && [ "$IGW" = "true" ]; then
TFAPPLY+=( -var="allow_outgoing_internet=true")
fi
if [ -n "$NOCMK" ]; then
if [ "$NOCMK" = "all" ]; then
TFAPPLY+=( -var="cmk_managed=false")
TFAPPLY+=( -var="cmk_storage=false")
else
TFAPPLY+=( -var="cmk_$NOCMK=false")
fi
fi

terraform init

if [ -n "$FRONT_END_PL_SUBNET_IDS" ]; then
TFAPPLY+=( -var="front_end_pl_subnet_ids=$FRONT_END_PL_SUBNET_IDS")
fi

if [ -n "$FROND_END_PL_SOURCE_SUBNET_IDS" ]; then
TFAPPLY+=( -var="front_end_pl_source_subnet_ids=$FROND_END_PL_SOURCE_SUBNET_IDS")
fi

# Apply terraform template to provision AWS and Databricks infra for a Workspace
# If $FRONT_END_PL_SUBNET_IDS is provided will also create Front End VPC Endpoint in those subnets
"${TFAPPLY[@]}"

if [ -n "$FRONT_END_ACCESS" ]; then
TFAPPLY+=( -var="front_end_access=$FRONT_END_ACCESS")
fi

# Need to setup Databricks VPC Endpoint DNS resolution which can only be done after the VPC Endpoint has been accepted after configuration
"${TFAPPLY[@]}" -var="private_dns_enabled=true"
