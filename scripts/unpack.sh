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
TOTAL_DECOMP_ARCHIVE=0
TOTAL_NOT_DECOMP_FILES=0


function unpack_with_quirks() {
  local \
    archive \
    rc
  local -a \
    quirky_unpack
  archive="${1?FATAL - missing archive}"
  shift 1
  quirky_unpack+=("${@}")

  tar zxf "${archive}" || { log_error "unpacking failed"; exit "${rc}"; }
  log_info "unpacked ${archive}"


  [[ "${CLEANUP}" -gt 0 ]] && add_on_exit rm -f "${PWD}/${archive}"

  if [[ "${#quirky_unpack[@]}" -gt 0 ]]; then
    log_info "this package requires a quirk after the unpacking command: ${quirky_unpack[*]}"
    "${quirky_unpack[@]}"
  fi
  [[ "${CLEANUP}" -gt 0 ]] && add_on_exit rm -fr "${PWD}/${SRC_DIR}"
  return 0
}


function unpack() {

    local \
        archive \
        compression_type \
        rc
    local -a \
        unpack_files

    archive="${1?FATAL - missing archive}"
    unpack_files+=("${@}")

    echo "${DEST_DIR}"
    echo "${unpack_files[@]}"

  # Iterate over the filenames
  # shellcheck disable=SC2043
    for target in "${unpack_files[@]}"; do
        # Check if the target is a directory
        if [ -d "${target}" ]; then
            echo "Processing directory: ${target}"
            # Process each file in the directory
            for file in "${target}"/*; do
                unpack "${file}"
            done
        else
            unpack_archive "${target}"
        fi

    done
    [[ "${TOTAL_DECOMP_ARCHIVE}" -gt 0 ]] && \
        echo "Total archives that decompressed = ${TOTAL_DECOMP_ARCHIVE}"
    [[ "${TOTAL_NOT_DECOMP_FILES}" -gt 0 ]] && \
        echo "Total files that did NOT decompress = ${TOTAL_NOT_DECOMP_FILES}"
}

function unpack_archive() {

    local \
        archive \
        compression_type \
        rc

    archive="${1}"

    echo "Processing archive: ${archive}"
    # Determine the compression type of the file
    compression_type=$(file "$archive" | awk -F': ' '{print $2}')

    # Decompress the file based on the compression type
    case $compression_type in
    gzip*)
        echo "Decompressing gzip archive..."
        gunzip -k "${archive}" -c > "${DEST_DIR}/$(basename "${archive%.*}")_gz" && rc=$? || rc=$?
        echo "File processed."

        TOTAL_DECOMP_ARCHIVE=$((TOTAL_DECOMP_ARCHIVE+1))
        ;;
    bzip2*)
        echo "Decompressing bzip2 archive..."
        bzip2 -dc "$archive" > "${DEST_DIR}/$(basename "${archive%.*}")_bz2" && rc=$? || rc=$?
        echo "File processed."

        TOTAL_DECOMP_ARCHIVE=$((TOTAL_DECOMP_ARCHIVE+1))
        ;;
    Zip*)
        echo "Decompressing zip archive..."
        unzip "${archive}" -d "${DEST_DIR}" && rc=$? || rc=$?
        echo "File processed."

        TOTAL_DECOMP_ARCHIVE=$((TOTAL_DECOMP_ARCHIVE+1))
        ;;
    compress*)
        echo "Decompressing compressed archive..."
        gzip -d -c "${archive}" > "${DEST_DIR}/$(basename "${archive%.*}")_cmpr" && rc=$? || rc=$?
        echo "File processed."

        TOTAL_DECOMP_ARCHIVE=$((TOTAL_DECOMP_ARCHIVE+1))
        ;;
    *)
        # TODO: should be part of -v (verbose)
        echo "The file ${archive} wasn't decompressed."
        TOTAL_NOT_DECOMP_FILES=$((TOTAL_NOT_DECOMP_FILES+1))
        ;;
    esac

    # if [[ "${rc}" -ne 0 ]]; then
    #     log_error "Failed to create archive: ${archive}, rc=${rc}"
    #     exit "${rc}"
    # fi
    # log_info "Successfully built ${package}-${version} and generated archive: ${archive}"
    # return "${rc}"

    rc=$?
    return "${rc}"
}

# Usage example:
DATA_DIR="./welcome"
files=("${DATA_DIR}/archive.gz" "${DATA_DIR}/archive.bz2" "${DATA_DIR}/archive.zip" "${DATA_DIR}/archive.cmpr" "${DATA_DIR}/simple.txt")

export DEST_DIR="./dest_dir"
unpack "${files[@]}"
