#!/usr/bin/env bash

# Set the default destination folder to the home directory
DEST_DIR="${DEST_DIR:-"${HOME}"}"
verbose=false
recursive=false

while getopts 'vr' opt; do
    case $opt in
        v) verbose=true ;;
        r) recursive=true ;;
        *) echo 'Error in command line parsing' >&2
            exit 1 ;;
    esac
done

shift "$(( OPTIND - 1 ))"


function unpack() {

    local \
        archive \
        compression_type \
        verbose \
        recursive \
        total_file_count \
        total_ignored_count
    local -a \
        unpack_files

    total_file_count=0
    total_ignored_count=0
    verbose=false
    recursive=false


    archive="${1?FATAL - missing archive}"
    unpack_files+=("${@}")

    # TODO: find out what are the difference of passing array vs $@
    if [ "${recursive}" = true ]; then
        find_archive_recursive "${@}"
    else
        find_archive "${@}"
    fi

    # Iterate over the archives
    for target in "${unpack_files[@]}"; do
        # TODO: remove verbose from expression
        find_archive "${target}" "${verbose}"
    done

    echo "Decompressed ${total_file_count} archive(s) "
    return "${total_ignored_count}"
}

function find_archive_recursive() {

    local arg \
        total_file_count \
        total_ignored_count
    local -a \
        unpack_files

    total_file_count=0
    total_ignored_count=0
    unpack_files+=("${@}")

    for file in "${unpack_files[@]}"; do
        if [[ -d "${file}" ]]; then

            # TODO: assign DEST_DIR to the specified
            DEST_DIR="${file}"

            while IFS= read -r -d '' file; do
                if [[ -f "$file" ]]; then
                    # unpack_archive "${file}"
                    unpack_archive "${file}" \
                        && total_file_count=$((total_file_count+1)) \
                                            || total_ignored_count=$((total_ignored_count+1))
                fi

                # if [[ $? -eq 0 ]]; then
                #     total_file_count=$((total_file_count+1))
                # else
                #     total_ignored_count=$((total_ignored_count+1))
                # fi
            done < <(find "${file}" -type f -print0)

        elif [[ -f "${file}" ]]; then
            unpack_archive "${file}" \
                        && total_file_count=$((total_file_count+1)) \
                                            || total_ignored_count=$((total_ignored_count+1))
        fi
    done

    echo "Decompressed ${total_file_count} archive(s) "
    return "${total_ignored_count}"
}

function find_archive() {

    local \
        total_file_count \
        total_ignored_count
    local -a \
        unpack_files

    total_file_count=0
    total_ignored_count=0
    unpack_files+=("${@}")

    for arc_file in "${unpack_files[@]}"; do
        if [[ -d "${arc_file}" ]]; then
            # TODO: assign DEST_DIR to the specified
            DEST_DIR="${file}"

            files=("${arc_file}"/*)
            # for file in "${files[@]}"; do
            #     if [ -f "${file}" ]; then
            #         unpack_archive "${file}" \
            #             && total_file_count=$((total_file_count+1)) \
            #                                 || total_ignored_count=$((total_ignored_count+1))
            #     fi
            # done
        elif [[ -f "${arc_file}" ]]; then
            # TODO: assign DEST_DIR to the specified
            DEST_DIR="${file}"

            files=("${arc_file}")
            # unpack_archive "${arc_file}" \
            #             && total_file_count=$((total_file_count+1)) \
            #                                 || total_ignored_count=$((total_ignored_count+1))
        fi
        # TODO: minimize the code by assignmen files with the right arguments
        for file in "${files[@]}"; do
                if [ -f "${file}" ]; then
                    unpack_archive "${file}" \
                        && total_file_count=$((total_file_count+1)) \
                                            || total_ignored_count=$((total_ignored_count+1))
                fi
        done
    done

    echo "Decompressed ${total_file_count} archive(s) "
    return "${total_ignored_count}"
}

# UNPACK WITH DESTINATION DIR
# refactor - does less code consider as function refactoring ?
# function unpack_archive() {
#     local \
#         archive \
#         verbose \
#         compression_type \
#         rc

#     archive="${1}"
#     verbose="${2}"

#     # Determine the compression type of the file
#     compression_type=$(file "$archive" | awk -F': ' '{print $2}')

#     # Decompress the file based on the compression type
#     case $compression_type in
#     gzip*)
#         [ "${verbose}" = true ] && echo "Unpacking ${archive}..."
#         gunzip -k "${archive}" -c > "${DEST_DIR}/$(basename "${archive}")"
#         rc=$?
#         ;;
#     bzip2*)
#         [ "${verbose}" = true ] && echo "Unpacking ${archive}..."
#         bzip2 -dc "$archive" > "${DEST_DIR}/$(basename "${archive}")"
#         rc=$?
#         ;;
#     Zip*)
#         [ "${verbose}" = true ] && echo "Unpacking ${archive}..."
#         unzip "${archive}" -d "${DEST_DIR}" > /dev/null
#         rc=$?
#         ;;
#     compress*)
#         [ "${verbose}" = true ] && echo "Unpacking ${archive}..."
#         gzip -d -c "${archive}" > "${DEST_DIR}/$(basename "${archive}")"
#         rc=$?
#         ;;
#     *)
#         [ "$verbose" = true ] && echo "Ignoring ${archive}"
#         rc=1
#         ;;
#     esac

#     return "${rc}"
# }

function unpack_archive() {

    local \
        dest_dir \
        opts \
        rc

    filename="${1}"
    file_type=$(file -b "$filename")

    case "$file_type" in
        gzip*)
            cmd="gunzip"
            opts="-f"
            dest_dir=""

            [ "${verbose}" = true ] && echo "Unpacking ${filename}..."
            gunzip -f "${filename}" > /dev/null
            ;;
        bzip2*)
            cmd="bunzip2"
            opts=""
            dest_dir=""

            [ "${verbose}" = true ] && echo "Unpacking ${filename}..."
            bunzip2 -c "${filename}" > "${filename}.bz2"
            ;;
        Zip*)
            cmd="unzip -o"
            opts="-d"
            dest_dir=$(dirname "${filename}")

            [ "${verbose}" = true ] && echo "Unpacking ${filename}..."
            unzip -o "${filename}" -d "${dest_dir}" > /dev/null
            ;;
        compress*)
            cmd="gzip"
            opts="-d -c"
            dest_dir="> ${filename%.*}"

            [ "${verbose}" = true ] && echo "Unpacking ${filename}..."
            gzip -d -c "${filename}" > "${filename%.*}"
            ;;
        *)
            [ "$verbose" = true ] && echo "Ignoring ${filename}"
            return 1
            ;;
    esac

    # echo "$cmd $opts $filename $dest_dir"

    # if [ $? -eq 0 ]; then
    #     return 0
    # fi
    rc=$?
    return "${rc}"
}

# Usage example:
DATA_DIR="welcome"
files=("${DATA_DIR}/archive.gz" "${DATA_DIR}/archive.bz2" "${DATA_DIR}/archive.zip" "${DATA_DIR}/archive.cmpr" "${DATA_DIR}/simple.txt")

# export DEST_DIR="./dest_dir"

# unpack "${files[@]}"
# unpack "${files[@]:0:2}"

# unpack "${files[@]:0:4}"

# unpack -j "${files[@]}"
# unpack -v "${files[@]}"
# unpack -r "${files[@]}"
# unpack -v -r "${files[@]}"
# unpack -v -r "${files[@]:0:5}"

# unpack $DATA_DIR
# unpack -v *
# unpack *

# unpack ./welcome_copy
# unpack -v -r $DATA_DIR
# unpack -r $DATA_DIR


# unpack "$@"

find_archive welcome_copy