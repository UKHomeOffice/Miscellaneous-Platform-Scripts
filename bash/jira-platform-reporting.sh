#!/bin/bash

# This script creates a report for all 
# incidents and service requests tickets
# assogned to the Platform Team

# Prerequisite:
# - install jq
# - connect to the vpn-acp-tunnel
# - user to be added to the jira-servicedesk-user group in jira

display_help() {
    echo "Usage: $0 [option...] "
    echo
    echo "   -u, --username           provide a username"
    echo "   -f, --from               provide date yyyy-mm-dd"
    echo "   -t, --to                 provide date yyyy-mm-dd"
    echo
    echo "example: $0 --username test_user --from 2021-05-01 --to 2021-05-31"
    echo
    exit 10
}

if [[ $# -ne 6 ]]; then
  echo "Please provide 3 parameters"
  echo
  display_help
fi

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -u|--username)
      USER="$2"
      shift
      shift
      ;;
    -f|--from)
      FROM="$2"
      validate_from=$( date -j -f "%Y-%m-%d" ${FROM} ); rtn=$?
      if [[ ${rtn} -ne 0 ]]; then
        echo "Please provide valid date in format: yyyy-mm-dd"
        exit 20
      fi
      shift
      shift
      ;;
    -t|--to)
      TO="$2"
      validate_to=$( date -j -f "%Y-%m-%d" ${TO} ); rtn=$?
      if [[ ${rtn} -ne 0 ]]; then
        echo "Please provide valid date in format: yyyy-mm-dd"
        exit 30
      fi
      shift
      shift
      ;;
    -h|--help)
      display_help
      ;;
    *)    # unknown option
      exit 40
      ;;
  esac
done

echo "Please enter your password: "
read -s PSWD

if [[ -z ${PSWD} ]]; then
  echo "Please rerun the script and enter your password when prompted"
  exit 50
fi

TO_MONTH=$( date -j -f "%Y-%m-%d" "${TO}" +%b )
FROM_MONTH=$( date -j -f "%Y-%m-%d" "${FROM}" +%b )
TO_YEAR=$( date -j -f "%Y-%m-%d" "${TO}" +%Y )
FROM_YEAR=$( date -j -f "%Y-%m-%d" "${FROM}" +%Y )

dir="./reports"

mkdir -p ${dir}

if [[ "${TO_MONTH}" == "${FROM_MONTH}" ]]; then
  filename="${dir}/${TO_MONTH}-${TO_YEAR}-Platform-Report.csv"
else
  filename="${dir}/${FROM_MONTH}-${TO_MONTH}-${FROM_YEAR}-Platform-Report.csv"
fi

echo "Jira Platform Reports from the ${FROM} to ${TO}"

touch ${filename}
chmod 777 ${filename}

echo "Ticket Number, Summary, Type, Priority, Service" > ${filename}

# variables for amount of tickets per service
db_count=0
gen_count=0
pcdp_count=0
es_count=0
ss_count=0
prau_count=0
tram_count=0

# variables for priority incident tickets
pcdp_P1=0
pcdp_P2=0
pcdp_P3P4=0
db_P1=0
db_P2=0
db_P3P4=0
es_P1=0
es_P2=0
es_P3P4=0
gen_P1=0
gen_P2=0
gen_P3P4=0
ss_P1=0
ss_P2=0
ss_P3P4=0
prau_P1=0
prau_P2=0
prau_P3P4=0
tram_P1=0
tram_P2=0
tram_P3P4=0

while IFS=$"\n" read -r key; do

	ticket=$( echo "${key}" | jq -r '.key' )
	summary=$( echo "${key}" | jq -r '.fields .summary' )
	priority=$( echo "${key}" | jq -r '.fields .customfield_12405 .value' )
	#createdEpoch=$( echo "${key}" | jq -r '.fields .customfield_11302 .currentStatus .statusDate .epochMillis' )
  type=$( echo "${key}" | jq -r '.fields .issuetype .name' )

	#if [[ -z ${createdEpoch} ]]; then
	#  created=""
  #else
  #  created=$( date -r $(( ${createdEpoch}/1000 )) +%Y%m%d )
  #fi

  # PCDP
  if [[ $( echo ${summary} | grep -iE 'R12|R17|PCDP' ) ]]; then

    service="PCDP"

    if [[ "${type}" == "Incident" && "${priority}" == "P1"  ]]; then
      pcdp_P1=$(( ${pcdp_P1} + 1 ))
    elif [[ "${type}" == "Incident" && "${priority}" == "P2"  ]]; then
      pcdp_P2=$(( ${pcdp_P2} + 1 ))
    elif [[ "${type}" == "Incident" ]]; then
      pcdp_P3P4=$(( ${pcdp_P3P4} + 1 ))
    else
      pcdp_count=$(( ${pcdp_count} + 1 ))
    fi

  # PRAU
  elif [[ $( echo ${summary} | grep -iE 'prau' ) ]]; then

    service="PRAU"
    if [[ "${type}" == "Incident" && "${priority}" == "P1"  ]]; then
      prau_P1=$(( ${prau_P1} + 1 ))
    elif [[ "${type}" == "Incident" && "${priority}" == "P2"  ]]; then
      prau_P2=$(( ${prau_P2} + 1 ))
    elif [[ "${type}" == "Incident" ]]; then
      prau_P3P4=$(( ${prau_P3P4} + 1 ))
    else
      prau_count=$(( ${prau_count} + 1 ))
    fi

    # TRaM
  elif [[ $( echo ${summary} | grep -iE 'tram' ) ]]; then

    service="TRaM"
    if [[ "${type}" == "Incident" && "${priority}" == "P1"  ]]; then
      tram_P1=$(( ${tram_P1} + 1 ))
    elif [[ "${type}" == "Incident" && "${priority}" == "P2"  ]]; then
      tram_P2=$(( ${tram_P2} + 1 ))
    elif [[ "${type}" == "Incident" ]]; then
      tram_P3P4=$(( ${tram_P3P4} + 1 ))
    else
      tram_count=$(( ${tram_count} + 1 ))
    fi

  # DB Support
  elif [[ $( echo ${summary} | grep -iE 'GP1|GP2|postgres|cpau|Greenplum|redshift|schema|CRS|database' ) ]]; then

    service="Databases"
    if [[ "${type}" == "Incident" && "${priority}" == "P1"  ]]; then
      db_P1=$(( ${db_P1} + 1 ))
    elif [[ "${type}" == "Incident" && "${priority}" == "P2"  ]]; then
      db_P2=$(( ${db_P2} + 1 ))
    elif [[ "${type}" == "Incident" ]]; then
      db_P3P4=$(( ${db_P3P4} + 1 ))
    else
      db_count=$(( ${db_count} + 1 ))
    fi

  # EntitySearch Support
  elif [[ $( echo "${summary}" | grep -iE 'entitysearch|entity search' ) ]]; then

    service="EntitySearch"

    if [[ "${type}" == "Incident" && "${priority}" == "P1" ]]; then
      es_P1=$(( ${es_P1} + 1 ))
    elif [[ "${type}" == "Incident" && "${priority}" == "P2" ]]; then
      es_P2=$(( ${es_P2} + 1 ))
    elif [[ "${type}" == "Incident" ]]; then
      es_P3P4=$(( ${es_P3P4} + 1 ))
    else
      es_count=$(( ${es_count} + 1 ))
    fi

  # Shared Services Support
  elif [[ $( echo "${summary}" | grep -iE 'shared services|Jira|Confluence|RocketChat' ) ]]; then

    service="Shared Services"

    if [[ "${type}" == "Incident" && "${priority}" == "P1" ]]; then
      ss_P1=$(( ${ss_P1} + 1 ))
    elif [[ "${type}" == "Incident" && "${priority}" == "P2" ]]; then
      ss_P2=$(( ${ss_P2} + 1 ))
    elif [[ "${type}" == "Incident" ]]; then
      ss_P3P4=$(( ${ss_P3P4} + 1 ))
    else
      ss_count=$(( ${ss_count} + 1 ))
    fi

  # General Support
  else

    service="General"

    if [[ "${type}" == "Incident" && "${priority}" == "P1" ]]; then
      gen_P1=$(( ${gen_P1} + 1 ))
    elif [[ "${type}" == "Incident" && "${priority}" == "P2" ]]; then
      gen_P2=$(( ${gen_P2} + 1 ))
    elif [[ "${type}" == "Incident" ]]; then
      gen_P3P4=$(( ${gen_P3P4} + 1 ))
    else
      gen_count=$(( ${gen_count} + 1 ))
    fi
  fi

	#echo "${created},${ticket},${summary},${type},${priority},${service}" >> ${filename}
  echo "${ticket},${summary},${type},${priority},${service}" >> ${filename}
done <<< "$( curl \
   -k \
   -s \
   -u ''${USER}'':''${PSWD}'' \
   -X POST \
   -H "Content-Type: application/json" \
   --data '{"jql":"project = PS AND created >= '${FROM}' AND created <= '${TO}' AND assignee in (Platform, membersof(platform)) ORDER BY createdDate ASC","startAt":0,"maxResults":500}' \
   "https://jira.dsa.homeoffice.gov.uk/rest/api/2/search" | jq -c '.issues[]' )"

# Creating report
echo "" >> ${filename}
echo "" >> ${filename}
echo ",P1 Incidents, P2 Incidents, P3/P4 Incidents, Service Requests" >> ${filename}
echo "General Support,${gen_P1}, ${gen_P2}, ${gen_P3P4}, ${gen_count}" >> ${filename}
echo "Database Support,${db_P1}, ${db_P2}, ${db_P3P4}, ${db_count}" >> ${filename}
echo "PCDP Support,${pcdp_P1}, ${pcdp_P2}, ${pcdp_P3P4}, ${pcdp_count}" >> ${filename}
echo "EntitySearch Support,${es_P1}, ${es_P2}, ${es_P3P4}, ${es_count}" >> ${filename}
echo "Shared Services Support,${ss_P1}, ${ss_P2}, ${ss_P3P4}, ${ss_count}" >> ${filename}
echo "PRAU Support,${prau_P1}, ${prau_P2}, ${prau_P3P4}, ${prau_count}" >> ${filename}
echo "TRaM Support,${tram_P1}, ${tram_P2}, ${tram_P3P4}, ${tram_count}" >> ${filename}


exit 0
