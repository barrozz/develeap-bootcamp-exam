#!/usr/bin/env bash


#### Validate variables:
# URL="${URL?FATAL URL is not set}"
# PKG="${PKG?FATAL PKG is not set}"
# VERSION="${VERSION?FATAL: VERSION is not set}"
# CLEANUP="${CLEANUP:-1}"
# ARCH="${ARCH:-"$(uname -m)"}"
# SRC_DIR="${SRC_DIR:-"${PKG}-${VERSION}"}"

# Set the default destination folder to the home directory
DEST_DIR="${DEST_DIR:-${HOME}}"

# function unpack_with_quirks() {
#   local \
#     archive \
#     rc
#   local -a \
#     quirky_unpack
#   archive="${1?FATAL - missing archive}"
#   shift 1
#   quirky_unpack+=("${@}")

#   tar zxf "${archive}" || { log_error "unpacking failed"; exit "${rc}"; }
#   log_info "unpacked ${archive}"


#   [[ "${CLEANUP}" -gt 0 ]] && add_on_exit rm -f "${PWD}/${archive}"

#   if [[ "${#quirky_unpack[@]}" -gt 0 ]]; then
#     log_info "this package requires a quirk after the unpacking command: ${quirky_unpack[*]}"
#     "${quirky_unpack[@]}"
#   fi
#   [[ "${CLEANUP}" -gt 0 ]] && add_on_exit rm -fr "${PWD}/${SRC_DIR}"
#   return 0
# }


function unpack() {

    local \
        dest_dir \
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

    while getopts 'vr' opt; do
        case $opt in
            v) verbose=true ;;
            r) recursive=true ;;
            *) echo 'Error in command line parsing' >&2
                exit 1 ;;
        esac
    done


    shift "$(( OPTIND - 1 ))"

    # Iterate over the archives

    for target in "${unpack_files[@]}"; do
        # Check if the target is a directory
        if [ -d "${target}" ]; then
            echo "Processing directory: ${target}"
            # Process each file in the directory
            for file in "${target}"/*; do
                unpack "${file}"
            done
        else
            unpack_archive "${target}" "${verbose}" \
                            && total_file_count=$((total_file_count+1)) \
                                                || total_ignored_count=$((total_ignored_count+1))
        fi

    done

    echo "Decompressed ${total_file_count} archive(s) "
    # TODO: check if this expression is valid
    [[ "${total_ignored_count}" -gt 0 ]] && rc=1 || rc=0

    echo "rc - ${rc}"

    return "${rc}"
}

function unpack_archive() {
    local \
        archive \
        dest_dir \
        verbose \
        compression_type \
        rc

    # # shellcheck disable=SC2034
    # local extension="${file##*.}"
    # # shellcheck disable=SC2034
    # local filename="${file%.*}"

    archive="${1}"
    verbose="${2}"
    dest_dir="${3}"

    # Determine the compression type of the file
    compression_type=$(file "$archive" | awk -F': ' '{print $2}')

    # Decompress the file based on the compression type
    case $compression_type in
    gzip*)
        [ "${verbose}" = true ] && echo "Unpacking ${archive}..."
        gunzip -k "${archive}" -c > "${DEST_DIR}/$(basename "${archive%.*}")_gz" && rc=$? || rc=$?
        ;;
    bzip2*)
        [ "${verbose}" = true ] && echo "Unpacking ${archive}..."
        bzip2 -dc "$archive" > "${DEST_DIR}/$(basename "${archive%.*}")_bz2" && rc=$? || rc=$?
        ;;
    Zip*)
        [ "${verbose}" = true ] && echo "Unpacking ${archive}..."
        unzip "${archive}" -d "${DEST_DIR}" && rc=$? || rc=$?
        ;;
    compress*)
        [ "${verbose}" = true ] && echo "Unpacking ${archive}..."
        gzip -d -c "${archive}" > "${DEST_DIR}/$(basename "${archive%.*}")_cmpr" && rc=$? || rc=$?
        ;;
    *)
        [ "$verbose" = true ] && echo "Ignoring ${archive}" && rc=1
        ;;
    esac

    return "${rc}"
}

# Usage example:
DATA_DIR="./welcome"
files=("${DATA_DIR}/archive.gz" "${DATA_DIR}/archive.bz2" "${DATA_DIR}/archive.zip" "${DATA_DIR}/archive.cmpr" "${DATA_DIR}/simple.txt")

export DEST_DIR="./dest_dir"

# unpack "${files[@]}"
unpack "${files[@]:0:2}"

# unpack -j "${files[@]}"
# unpack -v "${files[@]}"
# unpack -r "${files[@]}"
# unpack -v -r "${files[@]}"
# unpack -v -r "${files[@]:0:3}"

# unpack "$@"