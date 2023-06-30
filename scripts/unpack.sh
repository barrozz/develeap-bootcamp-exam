#!/usr/bin/env bash

# Set the default destination folder to the home directory
DEST_DIR="${DEST_DIR:-"${HOME}"}"
VERBOSE=false
RECURSIVE=false

while getopts 'vr' opt; do
    case $opt in
        v) VERBOSE=true ;;
        r) RECURSIVE=true ;;
        *) echo 'Error in command line parsing' >&2
            exit 1 ;;
    esac
done

shift "$(( OPTIND - 1 ))"

function unpack() {

    local \
        archive \
        compression_type \
        VERBOSE \
        RECURSIVE \
        total_file_count \
        total_ignored_count
    local -a \
        unpack_files

    total_file_count=0
    total_ignored_count=0
    VERBOSE=false
    RECURSIVE=false


    archive="${1?FATAL - missing archive}"
    unpack_files+=("${@}")

    # TODO: find out what are the difference of passing array vs $@
    if [ "${RECURSIVE}" = true ]; then
        find_archive_RECURSIVE "${@}"
    else
        find_archive "${@}"
    fi

    # Iterate over the archives
    for target in "${unpack_files[@]}"; do
        # TODO: remove VERBOSE from expression
        find_archive "${target}" "${VERBOSE}"
    done

    echo "Decompressed ${total_file_count} archive(s) "
    return "${total_ignored_count}"
}

function find_archive() {

    local \
        total_file_count \
        total_ignored_count
    local -a \
        unpack_files \
        files

    total_file_count=0
    total_ignored_count=0
    unpack_files+=("${@}")

    for arc_file in "${unpack_files[@]}"; do
        if [[ -d "${arc_file}" ]]; then
            # TODO: assign DEST_DIR to the specified
            DEST_DIR="${file}"

            if [ "${RECURSIVE}" = true ]; then
                mapfile -t files < <(find "${arc_file}" -type f)
            else
                files=("${arc_file}"/*)
            fi

        elif [[ -f "${arc_file}" ]]; then
            # TODO: assign DEST_DIR to the specified
            DEST_DIR="${file}"
            files=("${arc_file}")
        fi

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
# function unpack_archive() {
#     local \
#         archive \
#         VERBOSE \
#         compression_type \
#         rc

#     archive="${1}"
#     VERBOSE="${2}"

#     # Determine the compression type of the file
#     compression_type=$(file "$archive" | awk -F': ' '{print $2}')

#     # Decompress the file based on the compression type
#     case $compression_type in
#     gzip*)
#         [ "${VERBOSE}" = true ] && echo "Unpacking ${archive}..."
#         gunzip -k "${archive}" -c > "${DEST_DIR}/$(basename "${archive}")"
#         rc=$?
#         ;;
#     bzip2*)
#         [ "${VERBOSE}" = true ] && echo "Unpacking ${archive}..."
#         bzip2 -dc "$archive" > "${DEST_DIR}/$(basename "${archive}")"
#         rc=$?
#         ;;
#     Zip*)
#         [ "${VERBOSE}" = true ] && echo "Unpacking ${archive}..."
#         unzip "${archive}" -d "${DEST_DIR}" > /dev/null
#         rc=$?
#         ;;
#     compress*)
#         [ "${VERBOSE}" = true ] && echo "Unpacking ${archive}..."
#         gzip -d -c "${archive}" > "${DEST_DIR}/$(basename "${archive}")"
#         rc=$?
#         ;;
#     *)
#         [ "$VERBOSE" = true ] && echo "Ignoring ${archive}"
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

            [ "${VERBOSE}" = true ] && echo "Unpacking ${filename}..."
            gunzip -f "${filename}" > /dev/null
            ;;
        bzip2*)
            cmd="bunzip2"
            opts=""
            dest_dir=""

            [ "${VERBOSE}" = true ] && echo "Unpacking ${filename}..."
            bunzip2 -c "${filename}" > "${filename}.bz2"
            ;;
        Zip*)
            cmd="unzip -o"
            opts="-d"
            dest_dir=$(dirname "${filename}")

            [ "${VERBOSE}" = true ] && echo "Unpacking ${filename}..."
            unzip -o "${filename}" -d "${dest_dir}" > /dev/null
            ;;
        compress*)
            cmd="gzip"
            opts="-d -c"
            dest_dir="> ${filename%.*}"

            [ "${VERBOSE}" = true ] && echo "Unpacking ${filename}..."
            gzip -d -c "${filename}" > "${filename%.*}"
            ;;
        *)
            [ "$VERBOSE" = true ] && echo "Ignoring ${filename}"
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

# export DEST_DIR="./dest_dir"

find_archive "$@"