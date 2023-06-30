#!/usr/bin/env bash

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

            if [ "${RECURSIVE}" = true ]; then
                mapfile -t files < <(find "${arc_file}" -type f)
            else
                files=("${arc_file}"/*)
            fi

        elif [[ -f "${arc_file}" ]]; then
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


function unpack_archive() {

    local \
        dest_dir \
        opts

    filename="${1}"
    file_type=$(file -b "$filename")

    case "$file_type" in
        gzip*)
            [ "${VERBOSE}" = true ] && echo "Unpacking ${filename}..."
            [[ "${extension}" != "gz" ]] && mv "${filename}" "${filename}.gz"
            gunzip -f "${filename}" 2>/dev/null
            ;;
        bzip2*)
            extension="${filename##*.}"

            [ "${VERBOSE}" = true ] && echo "Unpacking ${filename}..."
            if [[ "${extension}" == "bz2" ]]; then
                bunzip2 -c "${filename}" > "${filename%.*}_bz2"
                rm "${filename}"
                mv "${filename%.*}_bz2" "${filename}"
            else
                bunzip2 -f "${filename}" 2>/dev/null
                mv "${filename}.out" "${filename}"
            fi
            ;;
        Zip*)
            dest_dir=$(dirname "${filename}")

            [ "${VERBOSE}" = true ] && echo "Unpacking ${filename}..."
            unzip -o "${filename}" -d "${dest_dir}" > /dev/null
            ;;
        compress*)
            [ "${VERBOSE}" = true ] && echo "Unpacking ${filename}..."
            mv "${filename}" "${filename}.Z"
            uncompress "${filename}"
            ;;
        *)
            [ "$VERBOSE" = true ] && echo "Ignoring ${filename}"
            return 1
            ;;
    esac
    return $?
}

find_archive "$@"