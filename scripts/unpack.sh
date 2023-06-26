#!/usr/bin/env bash

# TODO: #!/usr/bin/env bash vs #!/usr/bin/bash

#### Validate variables:
# URL="${URL?FATAL URL is not set}"
# PKG="${PKG?FATAL PKG is not set}"
# VERSION="${VERSION?FATAL: VERSION is not set}"
# CLEANUP="${CLEANUP:-1}"
# ARCH="${ARCH:-"$(uname -m)"}"
# SRC_DIR="${SRC_DIR:-"${PKG}-${VERSION}"}"

# Set the default destination folder to the home directory
DEST_DIR="${DEST_DIR:-${HOME}}"

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
        total_decompress_archives \
        total_not_decompress_files
    local -a \
        unpack_files

    archive="${1?FATAL - missing archive}"
    shift 1
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
                process_files "${file}"
            done
        else
            echo "Processing file: ${target}"
            # Determine the compression type of the file
            compression_type=$(file "$target" | awk -F': ' '{print $2}')

            # Decompress the file based on the compression type
            case $compression_type in
            gzip*)
                echo "Decompressing gzip-compressed file..."
                gunzip -k "${target}" -c > "${DEST_DIR}/$(basename "${target}" .gz)_gz"
                echo "File processed."

                total_decompress_archives=$((total_decompress_archives+1))
                ;;
            bzip2*)
                echo "Decompressing bzip2-compressed file..."
                bzip2 -dc "$target" > "${DEST_DIR}/$(basename "${target}" .bz2)_bz2"
                echo "File processed."

                total_decompress_archives=$((total_decompress_archives+1))
                ;;
            Zip*)
                echo "Decompressing zip archive..."
                unzip "${target}" -d "${DEST_DIR}"
                echo "File processed."

                total_decompress_archives=$((total_decompress_archives+1))
                ;;
            compress*)
                echo "Decompressing compress-compressed file..."
                gzip -d -c "${target}" > "${DEST_DIR}/$(basename "${target}" .cmpr)_cmpr"
                echo "File processed."

                total_decompress_archives=$((total_decompress_archives+1))
                ;;
            *)
                # TODO: should be part of -v (verbose)
                echo "The file ${target} wasn't decompressed."
                total_not_decompress_files=$((total_not_decompress_files+1))
                ;;
            esac
        fi
    done
    [[ "${total_decompress_archives}" -gt 0 ]] && \
        echo "Number of archives that decompressed = ${total_decompress_archives}"
    [[ "${total_not_decompress_files}" -gt 0 ]] && \
        echo "Number of files that did NOT decompress = ${total_not_decompress_files}"
}


# TODO: change the path to dest_dir - look at max's script

# Usage example:
DATA_DIR="./welcome"
destination="/path/to/destination/folder"
files=("${DATA_DIR}/archive.gz" "${DATA_DIR}/archive.bz2" "${DATA_DIR}/archive.zip" "${DATA_DIR}/archive.cmpr" "${DATA_DIR}/simple.txt")

export DEST_DIR="./dest_dir"
unpack "${DEST_DIR}" "${files[@]}"
