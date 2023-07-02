#!/usr/bin/env bash

# Default values
COUNT=-1
TIMEOUT=1
USERNAME="any user"

# Parse command-line arguments
while getopts "c:t:u:" opt; do

    case $opt in
        c)
            COUNT=$OPTARG
            ;;
        t)
            TIMEOUT=$OPTARG
            ;;
        u)
            USERNAME=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

shift "$(( OPTIND - 1 ))"

# count active processes for a specific user or all logged-in users
count_live_processes() {
    local exe_name \
        username \
        num_processes

    username="${1}"
    exe_name="${2}"

    num_processes=$(pgrep -l -U "${username}" | grep -cie "${exe_name}")

    echo "${exe_name}: ${num_processes} instance(s)..."
}

# function infinite_active_processes() {

#     local USERNAME \
#         exe_name

#     echo "Pinging '$exe_name' for USERNAME '$USERNAME' ${COUNT} times"

#     while true; do
#         count_live_processes "$USERNAME" "$exe_name"
#         sleep "$TIMEOUT"
#     done

# }

# function iterative_active_processes() {

#     local USERNAME \
#         exe_name

#     echo "Pinging '$exe_name' for USERNAME '$USERNAME' ${COUNT} times"

#     for ((i = 1; i <= COUNT; i++)); do
#         count_live_processes "$USERNAME" "$exe_name"
#         sleep "$TIMEOUT"
#     done
# }

if [[ $COUNT -eq -1 ]]; then
    loop_type="while true"
else
    loop_type="for i in {1..${COUNT}}"
fi

EXE_NAME="${1}"

# when no user is mentioned [-u user-name], get all the users that are currently logged in.
if [ "${USERNAME}" = "any user" ]; then
    USER="$(users)"
else
    USER="${USERNAME}"
    USERNAME="user '${USERNAME}'"
fi

echo "Pinging '${EXE_NAME}' for ${USERNAME}"

PSPING="${loop_type}; do \
    count_live_processes ${USER} ${EXE_NAME}; \
    sleep ${TIMEOUT}; \
    done"

eval "${PSPING}"