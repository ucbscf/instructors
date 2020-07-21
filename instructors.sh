#!/bin/bash
# vim: set et sw=4 ts=4:

set -e

grouper_cli_creds="secrets/grouper.json"
grouper_base_uri="https://calgroups.berkeley.edu/gws/servicesRest/json/v2_2_100"
group_prefix="edu:berkeley:org:stat:instructors:stat-instructors"

sis_cli_creds="secrets/sis.json"
sis_subject_area="STAT"
sis_terms="previous current next"

for term in ${sis_terms}; do
    # get the numeric SIS term id
    term_id=$(sis -f ${sis_cli_creds} term -p ${term})
    echo "term_id: ${term_id}"

    # get the list of classes in the specified term for the given subject area
    classes="$(sis -f ${sis_cli_creds} classes -s ${sis_subject_area} -t ${term_id} -i class-number)"
    echo "classes: ${classes}"

    # initialize our list of instructors for this term
    instructors_file=/tmp/${term}.txt
    > ${instructors_file}

    # get the instructors for the given class number
    for class in $classes ; do
        sis -f ${sis_cli_creds} people -t $term_id -n $class -c \
            instructors --exact >> ${instructors_file}
    done

    # replace all members of the calgroup with those we just obtained
    echo "R ${group_prefix}-${term}"
    grouper -C ${grouper_cli_creds} -B ${grouper_base_uri} add -r \
        -g ${group_prefix}-${term} -i ${instructors_file}
done
