#!/bin/bash
set -m
delete_all_existing_smoke_test() {
	echo "[Test Preparation] Deleting smoke test jobs and pods"
	$KUBECTL_CMD get job -n hzp | grep smoke-test | awk '{print $1}' | xargs $KUBECTL_CMD delete job -n hzp --ignore-not-found
	$KUBECTL_CMD get pod -n hzp | grep smoke-test | awk '{print $1}' | xargs $KUBECTL_CMD delete pod -n hzp --ignore-not-found

}

check_manifest_file_exists() {
	if [ -e "${manifest_file_path}" ]; then
		echo "[Parameter] Manifest file path exists. ${manifest_file_path}"
		manifest_file_path=$(readlink -f "${manifest_file_path}")
	else
		echo "[Error] Manifest file path does not exist."
		exit 1;
	fi
}

get_smoke_test_image_tag() {
	local smoke_test_image_name=$1
	local smoke_test_image_tag=$(< "values.yaml" yq ".test.image.tag")
	if [ -n "${manifest_file_path}" ]; then 
		image_tag_from_manifest=$(yq eval ".global.components[] | select(.image == \"${smoke_test_image_name}\") | .version" "${manifest_file_path}")
		if [ -n "${image_tag_from_manifest}" ]; then
			smoke_test_image_tag="${image_tag_from_manifest}"
		fi
	fi
	echo "${smoke_test_image_tag}"
}

check_execute_test(){
	local service=$1
	local chart_directory=""
  # Check if the service is present in the MNGMT_CHARTS_FOLDER
    if [ -d "$MNGMT_CHARTS_FOLDER/$service" ]; then
      echo "[Service Found] $service found in $MNGMT_CHARTS_FOLDER"
      chart_directory="$MNGMT_CHARTS_FOLDER/"

      return 0
    #fi

    # Check if the service is present in the CHARTS_FOLDER
    elif [ -d "$CHARTS_FOLDER/$service" ]; then
      echo "[Service Found] $service found in $CHARTS_FOLDER"
      chart_directory="$CHARTS_FOLDER/"


    # If the service is not found in either folder
    elif [ ! -d "$CHARTS_FOLDER/$service" ]; then
    		echo "[Invalid Chart Name] ${service} is not valid service for EO charts: ${CHARTS_FOLDER}"; return 1;

    elif [ ! -d "$MNGMT_CHARTS_FOLDER/$service" ]; then
        		echo "[Invalid Chart Name] ${service} is not valid service for EO charts: ${MNGMT_CHARTS_FOLDER}"; return 1;
    fi
	# Checking whether it's smoke-test
	if [ "$service" = "smoke-test" ];
	  then
	    cd ${EO_REPO_PATH}
      NEEDRESTART_MODE=a apt install jq -y
      make create-client-csr NAMESPACE=hzp
      make sign-client-csr NAMESPACE=hzp
      $KUBECTL_CMD get secret -n hzp tls-credential -o jsonpath="{.data.cacert}" | base64 --decode > tls_ca.crt
      openssl pkcs12 -export -in client.crt -inkey client.key -out client_ca.p12 -name certpemfile_ca -CAfile mtls_ca.crt -caname root -password pass:password
      keytool -importkeystore -destkeystore keystore.jks -deststorepass password -srckeystore client_ca.p12 -srcstoretype PKCS12 -alias certpemfile_ca -srcstorepass password
      openssl pkcs12 -export -in client.crt -inkey client.key -out client_invalid.p12 -name certpemfile -CAfile mtls_ca.crt -caname root -password pass:password
      keytool -importkeystore -destkeystore keystore_invalid.jks -deststorepass password -srckeystore client_invalid.p12 -srcstoretype PKCS12 -alias certpemfile -srcstorepass password
      mkdir -p /data/certs/
      cp mtls_ca.crt tls_ca.crt client.crt keystore* /data/certs/.
	fi
	# Check whether smoke-test.yaml exists
	yaml_file="${chart_directory}${service}/${SMOKETEST_YAML_PATH}";
	if test -f "$yaml_file";
	then
		# Check whether the test suite exists
		if [ "${test_suite}" == "eo-ece-regression.xml" ]
		then
			if no_eo_ece_regression_flag "$service" "$chart_directory";
			then return 1;
			fi;
		fi;
		# Check whether the test is runnning
		local test_running="${TEST_REPORT_FOLDER}${service}_test_running"
		if test -f "$test_running";
		then echo "[Test Skipped] $service - concurrent test detected"; return 1; fi

	else
		return 1;
	fi
}

no_eo_ece_regression_flag() {
	local service=$1
	local chart_directory=$2

	flag=$(< "${chart_directory}${service}/values.yaml" yq ".test.eoEceRegression")
	if [ "${flag}" == "true" ];
	then
		echo "[Test Detected] Found test.eoEceRegression flag is true, trigger test for ${service}";
		return 1;
	else
		echo "Not Found test.eoEceRegression flag, stop trigger test for ${service}";
		return 0;
 	fi
}

# Function to process a group of services
execute_group_tests() {
  # Split the argument into group_name and services using the colon delimiter
  	IFS=':' read -r group_name services <<< "$1"

	# Convert the services string into an array and trim each element
	IFS=' ' read -r -a services_array <<< "$services"
	trimmed_services=()
	for service in "${services_array[@]}"; do
		# Trim leading and trailing whitespace from each service
		service=$(echo "$service" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
		trimmed_services+=("$service")
	done

	echo "[$(date)][Running group tests for service][$group_name] : ${trimmed_services[*]}"

	for service in "${trimmed_services[@]}"; do
		echo "Running tests for service: $service"
		if check_execute_test "$service"; then
			  if [ -d "$MNGMT_CHARTS_FOLDER/$service" ]; then
              chart_directory="$MNGMT_CHARTS_FOLDER/"
        fi

        if [ -d "$CHARTS_FOLDER/$service" ]; then
              chart_directory="$CHARTS_FOLDER/"
        fi
		reg_test "$service" "${chart_directory}" > "${TEST_LOG_FOLDER}/$service.log" 2>&1 &
		pid=$!
		echo "[Test Started] $service, background process id: $pid"
		group_pids+=" $pid"
		tests_waiting[$pid]="$service"
		fi
	done

for pid in $group_pids; do
    SECONDS=0
    while kill -0 $pid 2>/dev/null; do
        sleep 1
        if (( SECONDS > 2760 )); then
            echo "Timeout reached, killing process $pid"
            kill $pid
            break
        fi
    done
done
}


reg_test() {
	# Load environment variables
	source /root/hzp-eo-charts/.env

	local SVC_DIR=$1
	local chart_directory=$2

	# Disable concurrent test for the same service
	local svc_test_running="${TEST_REPORT_FOLDER}${SVC_DIR}_test_running"
	if test -f "$svc_test_running";
	then echo "Regression Test ${SVC_DIR} Already Running, Skip tests." && exit 1;
	else touch "$svc_test_running"
	fi

	# change working dir
	cd "${chart_directory}${SVC_DIR}" || { rm "$svc_test_running"; exit 2; }
	echo "[Test Initialization] [${SVC_DIR}] Preparing Smoke Test job for Service: ${SVC_DIR}, Test Suite: ${test_suite}"

	# Reading yaml to catch the smoketest image name
	SMOKETEST_JOB_NAME=$(helm --kube-context="${kube_cluster}" template -s templates/smoketest-job.yaml -f "${manifest_file_path}" -f"${EO_SERVICES_VALUES}" --set=global.regressionEnabled=true --set=test.enabled=true --set=global.istio.deploy=false --set=global.nginx_gw.enabled=true . | yq 'select(.kind == "Job")| .metadata.name')
	echo "Smoke Test Job: ${SMOKETEST_JOB_NAME}"
	SMOKETEST_IMAGE_NAME=$(< values.yaml yq ".test.image.name")
	echo "Smoke Test Image: ${SMOKETEST_IMAGE_NAME}"
	SMOKE_TEST_IMAGE_TAG=$(get_smoke_test_image_tag "$SMOKETEST_IMAGE_NAME")
        echo "Smoke Test Image Tag: ${SMOKE_TEST_IMAGE_TAG}"
	MSVC_NAME=$(< values.yaml yq ".svc.name")
	echo "MicroService Name: ${MSVC_NAME}"

	REPORT_LOCAL_DEST_PATH="/${TEST_REPORT_DIR}/${SVC_DIR}/"
	mkdir -p "${REPORT_LOCAL_DEST_PATH}"

	# Delete existing service if any
	echo "[Test Preparation] [${SVC_DIR}] Deleting existing smoke test job if any..."
	$KUBECTL_CMD delete -n "${NAMESPACE}" "job.batch/${SMOKETEST_JOB_NAME}" --cascade=foreground --ignore-not-found
	$KUBECTL_CMD wait --for=delete "job.batch/${SMOKETEST_JOB_NAME}" -n $NAMESPACE
	$KUBECTL_CMD delete pod -n "${NAMESPACE}" --selector=job-name="${SMOKETEST_JOB_NAME}" --ignore-not-found
	$KUBECTL_CMD wait --for=delete pod --selector=job-name="${SMOKETEST_JOB_NAME}" -n $NAMESPACE

	echo "Checking all pods are deleted"
	$KUBECTL_CMD get pod -n "${NAMESPACE}" --selector=job-name="${SMOKETEST_JOB_NAME}"

	# Generate new service & pod
	echo "[Test Preparation] [${SVC_DIR}] Initializing new smoke test job and pod"
	if [ "${test_suite}" == "eo-ece-regression.xml" ]; then
          test_group="EO-ECE"
          helm --kube-context="${kube_cluster}" template -s templates/smoketest-job.yaml -f "${manifest_file_path}" -f"${EO_SERVICES_VALUES}" --namespace=$NAMESPACE --set=global.regressionEnabled=true --set=test.enabled=true --set=test.image.tag="${SMOKE_TEST_IMAGE_TAG}" --set=global.ingress.fqdn="${FQDN}" --set=test.testsuite=test-suites/"${test_suite}" --set test.reportportal.rpendpoint="${RP_ENDPOINT}" --set test.reportportal.rpuuid="${RP_API_KEY}" --set test.reportportal.rpuuid="${RP_API_KEY}" --set test.reportportal.eourl="${HOST_IP}" --set test.reportportal.manifest="${MANIFEST_VERSION}" --set test.reportportal.ecemanifest="${ECE_MANIFEST_VERSION}" --set test.reportportal.suite="$test_group" --set test.reportportal.runid="${BUILD_NUMBER}" --set test.reportportal.release="${MANIFEST_SOURCE}" --set=global.istio.deploy=false --set=global.nginx_gw.enabled=true . | $KUBECTL_CMD apply -n $NAMESPACE -f - --cascade=foreground
        elif [ "${test_suite}" == "regression.xml" ]; then
          test_group="EO"
          helm --kube-context="${kube_cluster}" template -s templates/smoketest-job.yaml -f "${manifest_file_path}" -f"${EO_SERVICES_VALUES}" --namespace=$NAMESPACE --set=global.regressionEnabled=true --set=test.enabled=true --set=test.image.tag="${SMOKE_TEST_IMAGE_TAG}" --set=global.ingress.fqdn="${FQDN}" --set=test.testsuite=test-suites/"${test_suite}" --set test.reportportal.rpendpoint="${RP_ENDPOINT}" --set test.reportportal.rpuuid="${RP_API_KEY}" --set test.reportportal.rpuuid="${RP_API_KEY}" --set test.reportportal.eourl="${HOST_IP}" --set test.reportportal.manifest="${MANIFEST_VERSION}" --set test.reportportal.suite="$test_group" --set test.reportportal.runid="${BUILD_NUMBER}" --set test.reportportal.release="${MANIFEST_SOURCE}" --set test.eolocation="${EO_LOCATION}" --set=global.istio.deploy=false --set=global.nginx_gw.enabled=true . | $KUBECTL_CMD apply -n $NAMESPACE -f - --cascade=foreground
        fi
	POD_ID=$($KUBECTL_CMD get pods -n "${NAMESPACE}" --selector=job-name="${SMOKETEST_JOB_NAME}" --no-headers -o custom-columns=":metadata.name")

	# To handle the case when $KUBECTL_CMD apply creates more than 1 pods, allow 10 seconds for the final pod
	DESCRIBE=$($KUBECTL_CMD describe job -n $NAMESPACE "${SMOKETEST_JOB_NAME}" | grep -E "Pods Statuses: +1 Active / 0 Succeeded")
	pod_ready_timer=0
	until [ -n "${DESCRIBE}" ] || [[ $pod_ready_timer -gt 10 ]]; do
		DESCRIBE=$($KUBECTL_CMD describe job -n $NAMESPACE "${SMOKETEST_JOB_NAME}" | grep -E "Pods Statuses: +1 Active / 0 Succeeded")
		sleep 1; pod_ready_timer=$((pod_ready_timer+1));
	done
	echo "[Test Preparation] $($KUBECTL_CMD describe job -n $NAMESPACE "${SMOKETEST_JOB_NAME}" | grep -E "Pods Statuses")"
	POD_ID=$($KUBECTL_CMD get pods -n "${NAMESPACE}" --selector=job-name="${SMOKETEST_JOB_NAME}" --no-headers -o custom-columns=":metadata.name")
	if [ "$(echo "${POD_ID}" | wc -l)" -gt 1 ]; then
		echo "[Test End] More than one Test Pod Exists: ${POD_ID}"; rm "$svc_test_running"; exit 3;
	fi
	echo "[Test Start] [${SVC_DIR}] POD ID: ${POD_ID}"

	POD_STATUS=$($KUBECTL_CMD get pod "${POD_ID}" -n "${NAMESPACE}" -o jsonpath="{.status.phase}")
	echo "[Test Start]  [${SVC_DIR}] POD STATUS: ${POD_STATUS}"

	# Waiting for the pod status change to running
	if [ "$POD_STATUS" = "Pending" ]; then
		echo "[Test Pending] [${SVC_DIR}] Waiting for pod starts to run: ${POD_ID}"
		$KUBECTL_CMD wait --for=jsonpath="{.status.phase}"="Running" -n $NAMESPACE "pod/${POD_ID}" --timeout="${TIMEOUT_POD_PENDING}s" || \
		{ echo "[Test Failed] [${SVC_DIR}] Pod still not started after ${TIMEOUT_POD_PENDING} seconds";
		#Output information for troubleshooting
		echo "[Test Failed] [${SVC_DIR}] [Troubleshooting Info] Smoke Test pod describe: ${POD_ID}"
		$KUBECTL_CMD describe pod "$POD_ID" -n "${NAMESPACE}";
		echo -n "[Test Failed] [${SVC_DIR}] [Troubleshooting Info] Microservice pod ID: "
		SERVICE_POD=$($KUBECTL_CMD get pods -n "${NAMESPACE}" -o custom-columns=":metadata.name" | grep "${MSVC_NAME}")
		echo "${SERVICE_POD}"
		if [ -n "${SERVICE_POD}" ]; then
			echo "[Test Failed] [${SVC_DIR}] [Troubleshooting Info] Microservice pod logs: ${SERVICE_POD}"
			$KUBECTL_CMD logs "${SERVICE_POD}" -n "${NAMESPACE}" --all-containers
			echo "[Test Failed] [${SVC_DIR}] [Troubleshooting Info] Microservice pod describe: ${SERVICE_POD}"
			$KUBECTL_CMD describe pod "${SERVICE_POD}" -n "${NAMESPACE}"
		else
			echo "No service pod found."
		fi
		rm "$svc_test_running"; exit 4; }
	else
		if [  "$POD_STATUS" != "Running" ]; then
			echo "[Test Failed] [${SVC_DIR}] Pod status is not pending or running. Regression test will not start."
			$KUBECTL_CMD get pod "${POD_ID}" -n "${NAMESPACE}";
			rm "$svc_test_running"; exit 5;
		fi
	fi

	# Periodically checking keyword in pod log
	counter=0
	while [ "$POD_STATUS" = "Pending" ] || [ "$POD_STATUS" = "Running" ]; do
		if $KUBECTL_CMD logs "${POD_ID}" -n "${NAMESPACE}" | grep "Total tests run"; then
			echo "[Test Success] ${SVC_DIR} Test Finished in $counter seconds"
			break
		elif [ $((counter % 5)) -eq 0 ]; then
			echo "[Test ${POD_STATUS}]  ${SVC_DIR} Test Pod Status is ${POD_STATUS} in $counter seconds"
		fi

		POD_STATUS=$($KUBECTL_CMD get pod "${POD_ID}" -n hzp -o jsonpath="{.status.phase}");
		sleep 1; counter=$((counter + 1));
	done

	#Checking the log
	echo -n "[Test logs] [${SVC_DIR}] "
	$KUBECTL_CMD logs "${POD_ID}" -n "${NAMESPACE}"

	# Copying report files
	echo "[Test End] [${SVC_DIR}] Fetching Junit reports and emailable reports from pod..."
	$KUBECTL_CMD cp "${NAMESPACE}/${POD_ID}:/${REPORT_POD_PATH}/${HTML_REPORT}" "${REPORT_LOCAL_DEST_PATH}/${HTML_REPORT}"
	$KUBECTL_CMD cp "${NAMESPACE}/${POD_ID}:/${REPORT_POD_PATH}/${JUNIT_DIR}/" "${REPORT_LOCAL_DEST_PATH}/"
	echo "[Test End]  [${SVC_DIR}] Files Copied to ${REPORT_LOCAL_DEST_PATH}"
	ls "${REPORT_LOCAL_DEST_PATH}"
	rm "$svc_test_running"
}

show_help() {
    echo "This script is created to run regression tests for Edge Orchestrator services."
    echo "Usage: $0 [-b value] [-t value] [-s value] [-h]"
    echo "Example: $0 -b 1234 -t EO-regression.xml -s hzp-iam"
    echo "  -b   Jenkins Build number to group test report files, if not provided, reports will be output to folder 'adhoc'"
    echo "  -t   Test suite file name, default: regression.xml"
    echo "  -s   Service name to run regression test, if not provided, all services will be tested"
    echo "  -f   Manifest file path to fetch smoke-test images. If not provided, will fetch latest smoke-test image"
	echo "  -c   Kubernetes cluster name"
    echo "  -h   Show help"
}

# Default Input Parameters
build_number="adhoc"
test_suite="regression.xml"
manifest_file_path=""
kube_cluster=""
eo_chart_path="/root/hzp-eo-charts"
declare -a service_name

# Get options
while getopts ":b:t:f:s:c:e:h" opt; do
  case $opt in
    b) build_number="${OPTARG}";;
    t) test_suite="${OPTARG}";;
    f) manifest_file_path="${OPTARG}";;
    s) service_name+=("${OPTARG}");;
    c) kube_cluster="${OPTARG}";;
    e) eo_chart_path="${OPTARG}";;
    h) show_help; exit 0;;
    \?) echo "Invalid option: -${OPTARG}" >&2; exit 1;;
    :) echo "Option -${OPTARG} requires an argument." >&2; exit 1;;
  esac
done

# Define Constants and Paths
EO_REPO_PATH="${eo_chart_path}"
EO_SERVICES_VALUES="${EO_REPO_PATH}/native-edge-orchestrator/charts/edge-orchestrator-services/values.yaml"
CHARTS_FOLDER="${EO_REPO_PATH}/native-edge-orchestrator/charts/edge-orchestrator-services/charts/"
MNGMT_CHARTS_FOLDER="${EO_REPO_PATH}/native-edge-orchestrator/charts/eo-management/charts/"
SMOKETEST_YAML_PATH="templates/smoketest-job.yaml"
NAMESPACE="hzp"
TEST_REPORT_FOLDER="/test-report-${build_number}/"
TEST_REPORT_DIR="${TEST_REPORT_FOLDER}${build_number}"
TEST_LOG_FOLDER="${TEST_REPORT_DIR}/logs"
REPORT_POD_PATH="tests/test-output"
JUNIT_DIR="junitreports"
HTML_REPORT="emailable-report.html"
TIMEOUT_POD_PENDING=300
TEST_TIMEOUT=2700 #45 min timeout for tests
REGRESSION_CONFIG_FILE_PATH="${EO_REPO_PATH}/tests/scripts/regression_test_config.yaml"
if [[ "${kube_cluster}" != 'null' && "${kube_cluster}" != '' ]]; then
	KUBECTL_CMD="kubectl --context=${kube_cluster}"
else
	KUBECTL_CMD="kubectl"
fi


# Prepare Package
which yq | grep -q "yq" || snap install yq

# Check Input Parameters and Prepare for Regression Test
echo "[Test Initialization] Reading parameters for regression test..."
echo "[Parameter] Test Suite: ${test_suite}"
if [ "${build_number}" == "adhoc" ]; then
    echo "[Parameter] No Jenkins build number specified, Test Report will be output to ${TEST_REPORT_DIR}"
else
    echo "[Parameter] Jenkins build number: ${build_number}, Test Report will be output to ${TEST_REPORT_DIR}"
fi
rm -rf "$TEST_REPORT_DIR"


# If manifest file path specified, get smoke-test tag from manifest file
if [ -z "${manifest_file_path}" ]; then
        echo "[Parameter] No manifest file specified, will use the latest smoke test images"
else
        echo "[Parameter] Manifest file specified: ${manifest_file_path}"
        check_manifest_file_exists;
fi


# If service names not specified, run regression test for all charts
if [ ${#service_name[@]} -eq 0 ];
then
	echo "[Parameter] Service Name not specified, will run regression test for all services."
	service_name=( $(ls -1 "$CHARTS_FOLDER") )
  service_name+=( $(ls -1 "$MNGMT_CHARTS_FOLDER") )
	delete_all_existing_smoke_test;
else
	echo "[Parameter] Service Names Specified: ${service_name[*]}"
fi


# Starts Regression Tests
mkdir -p "${TEST_LOG_FOLDER}"
declare -A tests_waiting
export -f reg_test

# Initialize an associative array to hold services grouped by their group number
declare -A serviceToGroup

if [[ "$test_suite" == "eo-ece-regression.xml" ]]; then
  execute_order=$(yq eval '.EO-ECE.execute_order' "${REGRESSION_CONFIG_FILE_PATH}")
else
  execute_order=$(yq eval '.EO.execute_order' "${REGRESSION_CONFIG_FILE_PATH}")
fi

# Extract group names dynamically
group_names=$(echo "$execute_order" | yq e 'keys | .[]' -)
# Iterate over each group name and process the services in that group
for group_name in $group_names; do
    services=$(yq eval ".\"$group_name\"[]" <<< "$execute_order")
    for service in $services; do
        serviceToGroup["$service"]="$group_name"
    done
done

for service in "${!serviceToGroup[@]}"; do
    group="${serviceToGroup[$service]}"
    # echo "Service: $service belongs to Group: $group"
done

declare -A groupToTargetSvc
for svc in "${service_name[@]}"; do
    # Check if the service exists in serviceToGroup
    if [[ -n "${serviceToGroup[$svc]}" ]]; then
        # Fetch the group name for the service
        group="${serviceToGroup[$svc]}"
        # Append the service to the delimited string of services for this group
        groupToTargetSvc["$group"]+="${svc} "
    fi
done

# Transform keys into an indexed array for sorting
sortedKeys=()
for group in "${!groupToTargetSvc[@]}"; do
    sortedKeys+=("$group")
done

# Sort the indexed array of keys
IFS=$'\n' sortedKeys=($(sort <<<"${sortedKeys[*]}"))
unset IFS

# Iterate over the sorted keys and access the corresponding values in the associative array
for group in "${sortedKeys[@]}"; do
    services="${groupToTargetSvc[$group]}"
    IFS=' ' read -r -a services_array <<< "$services"

	# Trim the trailing comma from the string of services
    services="${services_array[*]}"

    execute_group_tests "$group: $services"
done

printf "%80s\n" " " | tr ' ' '=' # Print Separator Line

# Wait until all tests finished in background or timeout
echo "[Test Running] Initialized tests in background"
echo "Waiting for Regression Tests to finish in background..."
START_TIME=$(date +%s)
ELAPSED_TIME=0
until [ "$(jobs -r | wc -l)" -eq 0 ]; do
	TIMENOW=$(date +%s)
	ELAPSED_TIME=$((TIMENOW - START_TIME))
	echo "[Test Running] [$(date +%T)] Regression Tests are running, $(jobs -r | wc -l)/${#tests_waiting[@]} still in progress, Elapsed Time ${ELAPSED_TIME} seconds"
	for pid in $(jobs -pr); do echo "Process ${pid} is Running - ${tests_waiting[$pid]}"; done;
	sleep 20;
	# Kill all background process if timeout
	if [ $ELAPSED_TIME -gt $TEST_TIMEOUT ]; then
		echo "[Test Timeout] Exceeds timeout for regression test: 45 min"
		kill "$(jobs -p)"
		for svc in "${tests_waiting[@]}"; do
			[ -f "${TEST_REPORT_FOLDER}${svc}_test_running" ] && rm "${TEST_REPORT_FOLDER}${svc}_test_running"
		done
		break
	fi
done
echo "[Test End] All background process for regression tests are completed!"
printf "%80s\n" " " | tr ' ' '=' # Print Separator Line

# Print out all logs for tests
printf "%80s\n" " " | tr ' ' '=' # Print Separator Line
for log_file in "$TEST_LOG_FOLDER"/*; do
	cat "$log_file"
	printf "%80s\n" " " | tr ' ' '=' # Print Separator Line
done
rm -rf "${TEST_LOG_FOLDER}"

# List out all reports for tests
printf "%80s\n" " " | tr ' ' '=' # Print Separator Line
echo "[Test Report] All test reports collected: "
ls -R "$TEST_REPORT_DIR"/*
printf "%80s\n" " " | tr ' ' '=' # Print Separator Line

# Regression Test Exit reasons
declare -A exit_reason
exit_reason[1]="Concurrent Regression Test Detected"
exit_reason[2]="Failed to change working directory"
exit_reason[3]="Multiple Smoke Test Pod detected"
exit_reason[4]="Smoke Test Pod status stuck in pending for ${TIMEOUT_POD_PENDING} seconds"
exit_reason[5]="Smoke Test Pod is not pending after initialized"
exit_reason[143]="Killed background process due to regression test timeout: ${TEST_TIMEOUT} seconds"
exit_reason[0]="Test Completed"

# Print out summary for tests
printf "%80s\n" " " | tr ' ' '=' # Print Separator Line
echo "[Test Summary] Regression Test Run: ${#tests_waiting[@]} Services in total, Time Elapsed: $(($(date +%s) - $START_TIME)) Seconds"
for process in "${!tests_waiting[@]}"; do
	wait "$process";
	status="$?"
	echo -n "${tests_waiting[$process]} - PID: ${process} - ${exit_reason[$status]}"
	if [ $status -gt 0 ]; then echo " [Failed] "; else echo " [Success] "; fi
done

printf "%80s\n" " " | tr ' ' '=' # Print Separator Line
echo "All Regression Test are finished! "
