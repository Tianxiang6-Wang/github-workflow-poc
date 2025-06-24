while [ $# -gt 0 ]; do case $1 in --%[1]s_requirement=*) requirement=${1#*=}; shift ;; *) shift ;; esac; done;

[ -z "$requirement" ] && echo "%[2]s Requirement is empty" >&2 && exit 50
echo "%[2]s Requirement: $requirement"

for node in $(kubectl get nodes -o name);
do
allocatable=$(kubectl get "$node" -o json |jq -r 'def units: .|capture("(?<n>[0-9]+)(?<u>[A-Za-z]?)")|. as $v|($v.n|tonumber)*(if $v.u=="" then 1 else %[3]s end);
.status.allocatable."%[1]s"|units')

[ -z "$allocatable" ] && echo "Allocatable %[2]s is empty for $node" >&2 && exit 50

echo "Allocatable %[2]s for $node: $allocatable"

allocatedList=$(kubectl describe "$node" | grep 'Allocated resources:' -A 6 | grep %[1]s)
set -- $allocatedList
allocated=$2
[ -z "$allocated" ] && echo "Allocated %[2]s is empty for $node" >&2 && exit 50
allocated=$(echo "$2" | sed -e '%[4]s' | bc)
echo "Allocated %[2]s for $node: $allocated"

remaining=$(echo "$allocatable-$allocated" | bc)
echo "Remaining %[2]s for $node: $remaining"

[ -n "$(echo "$requirement" | jq 'select(. > '"$remaining"')')" ] && echo "Not enough remaining %[2]s with requirement $requirement" >&2 && exit 40
done
echo "%[2]s Health Check has Completed Successfully"
exit 20
