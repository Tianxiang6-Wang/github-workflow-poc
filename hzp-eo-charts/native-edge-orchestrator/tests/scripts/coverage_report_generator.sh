#!/bin/bash

SERVICE_MAPPING_FILE_PATH="/root/hzp-eo-charts/tests/scripts/service_mapping.yaml"

setup_env() {
  if ! command -v go &> /dev/null; then
    echo "go command not present so downloading go into the vm"
    wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz > /dev/null 2>&1
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    rm -rf go1.22.2.linux-amd64.tar.gz
  fi
  if [ ! -d "./coverage_report" ]; then
    mkdir "./coverage_report"
  fi

  cd "./coverage_report" || exit
}

generate_report_for_app() {
  app=$1
  service_name=$2
  container=""

  echo "Preparing coverage report with $app $service_name $container"

  selector_label=$(kubectl describe svc/"$service_name" -n hzp | grep Selector: | awk '{print $2}')
  echo "selector_label: $selector_label"
  pod_name=$(kubectl get pods -n hzp -l="$selector_label" -l="service.istio.io/canonical-name=$service_name" --output=name | cut -d'/' -f2)
  echo "pod_name: $pod_name"
  pod_ip=$(kubectl get pod "$pod_name" -n hzp -o jsonpath='{.status.podIP}')
  echo "pod_ip: $pod_ip"

  wget http://"$pod_ip":8888/save-coverage > /dev/null 2>&1

  if [ -d "./$app" ]; then
    rm -rf ./"$app"
  fi

  mkdir ./"$app"

  cd "./$app" || exit

  kubectl exec -n hzp $pod_name $container  -- tar cf - ./coverage | tar xf - -C .

  if [ -d "./coverage" ]; then
      cd ./coverage || exit
      go tool covdata textfmt -i=./ -o=./out.txt
      exclusions=$(yq eval '.coverage_exclusion_list[]' ./.drp/regressiontest_config.yml 2>/dev/null)
      for exclusion in $exclusions; do
        sed -i "/${exclusion//\//\\/}/d" ./out.txt
      done
      go tool cover -html=./out.txt -o=./coverage.html
      go tool cover -func=./out.txt -o=./func.out
      cp ./func.out ../func.out
      cp ./coverage.html ../coverage.html
      cp ./out.txt ../out.txt
      cd ../
      rm -rf ./coverage
      coverage=$(cat func.out | grep '^total:' | awk -F' ' '{print $3}')
      echo "$coverage" >> ./coverage_result.txt
      echo "coverage report for $app done successfully with $coverage"
  else
      echo "Errored" >> ./coverage_result.txt
      echo "coverage report for $app failed"
  fi
  cd ../
}


main() {
  setup_env
  # Read the yaml file and assign the values to folder_name and service_name
  service_count=$(yq e '.services | length' "${SERVICE_MAPPING_FILE_PATH}")
  for ((i=0; i<service_count; i++)); do
                  folder_name=$(yq e ".services[$i].service.folder_name" "${SERVICE_MAPPING_FILE_PATH}")
                  service_name=$(yq e ".services[$i].service.service_name" "${SERVICE_MAPPING_FILE_PATH}")
                  if [ "${service_name}" == "null" ]; then
                      service_name="$folder_name"
                  fi
                  echo "Running coverage for: $folder_name:$service_name"
                  generate_report_for_app "$folder_name" "$service_name"
              done
              }

main "$@"

