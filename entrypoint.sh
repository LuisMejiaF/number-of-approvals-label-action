#!/bin/bash
set -e

if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "Set the GITHUB_TOKEN env variable."
    exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
    echo "Set the GITHUB_REPOSITORY env variable."
    exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
    echo "Set the GITHUB_EVENT_PATH env variable."
    exit 1
fi

addLabel=$INPUT_ICON # TODO: Change to `icon`

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
#state=$(jq --raw-output .review.state "$GITHUB_EVENT_PATH")
#number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
number=4200

add_label() {
    LABEL_TO_ADD=$1

    curl -sSL \
        -H "${AUTH_HEADER}" \
        -H "${API_HEADER}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"labels\":[\"${LABEL_TO_ADD}\"]}" \
        "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels"
}

remove_label() {
    curl -sSL \
        -H "${AUTH_HEADER}" \
        -H "${API_HEADER}" \
        -X DELETE \
        "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/${addLabel}"
}

label_when_approved() {
    body=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}/reviews?per_page=100")
    reviews=$(echo "$body" | jq --raw-output '.[] | {state: .state} | @base64')

    approvals=0

    for r in $reviews; do
        review="$(echo "$r" | base64 -d)"
        reviewState=$(echo "$review" | jq --raw-output '.state')

        if [[ "$reviewState" == "APPROVED" ]]; then
            approvals=$((approvals + 1))
        fi
    done

    APPROVAL_LABEL="Approvals"

    for (( i=1; i<=approvals; i++ ))
    do
       APPROVAL_LABEL+=" :white_check_mark:"
    done

    add_label ${APPROVAL_LABEL}
}

label_when_approved

#if [[ "$action" == "submitted" ]] && [[ "$state" == "approved" ]]; then
#    label_when_approved
#else
#    echo "Ignoring event ${action}/${state}"
#fi
