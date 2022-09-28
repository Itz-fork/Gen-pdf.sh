#!/usr/bin/bash


#################### SCRIPT START ####################


# ----------------- Script version -----------------#
Version="v0.3"


# ------------------ Colors codes ------------------#
WHITE="\033[1;37m"
BLACK="\033[1;30m"
YELLOW="\033[1;93m"
GREEN="\033[1;92m"
RED="\033[1;31m"
CYAN_BACK="\033[1;46m"
GREEN_BACK="\033[1;42m"
RESET="\033[0m"


#----------------- Argument parser -----------------#
while [[ $# -gt 0 ]]; do
    case "${1}" in
        -d|--dir)
            fpath="$2"
            fname=$(basename "$2")
            shift
            shift
            ;;
        -o|--out)
            out_dir="$2"
            shift
            shift
            ;;
        -m|--merge)
            merge="true"
            shift
            ;;
        *)
            echo -e "${WHITE}
Usage:
    bash generate.sh

Arguments:
    -d|--dir - Path to the folder that contains images
    -o|--out - Output directory
    -m|--merge - Merge generated pdfs into one
${RESET}"
            exit 1
    esac
done


#-------------------- Functions --------------------#
show_process() {
    echo -e "${WHITE}$1${RESET}"
}

show_info() {
    echo -e "  ${YELLOW}[!] $1${RESET}"
}

throw_error() {
    echo -e "   ${RED}[WARNING!] $1${RESET}"
    exit 1
}

check_dependencies() {
    declare -a depends=("convert" "pdftools")
    for pack in "${depends[@]}"; do
        CHCK=$(command -v "$pack" &> /dev/null)
        if ! $CHCK; then
            throw_error "Package $pack not found!"
        fi
    done
}

create_tmp_dir() {
    if [[ $current_dir != "$out_dir" ]]; then
        mkdir -p "$out_dir"
        chtmp="$out_dir/$fname-generated"
    else
        chtmp="$fname-generated"
    fi
    if [ -d "$chtmp" ]; then
        show_info "Removing existing pdfs in $chtmp!"
        rm -rf "$chtmp"
    fi
    mkdir "$chtmp"
}

get_subfolders() {
    show_process "> Scanning for sub-folders..."
    
    folders=$(find "$fpath"/ -maxdepth 1 -mindepth 1 -type d | sort -nk1.8)
    folders_count=$(printf %s "$folders" | wc -l)
    show_info "Found $folders_count sub-folders inside $fname\n"
}

generate_pdfs() {
    show_process "> Generating pdfs"
    if [[ $folders_count != "0" ]]; then
        for i in $folders; do
            local pdfname
            pdfname=$(basename "$i")
            echo -e "  ${GREEN}[+]${RESET} Generating pdf for $pdfname"
            convert "$i/*.jpg" "$chtmp/$pdfname.pdf"
        done
    else
        echo -e "  ${GREEN}[+]${RESET} Generating pdf for $fname"
        convert "$fpath/*.jpg" "$chtmp/$fname.pdf"
    fi
}

merge_pdf() {
    show_process "\n> Merging $folders_count pdfs into single pdf..."
	pdftools merge -o "$out_dir/$fname.pdf" "$chtmp"/*.pdf
}

main() {
    # Check if the required packages are installed
    check_dependencies
    # Show heading
    echo -e "${CYAN_BACK}${BLACK}Gen-pdf.sh - ${Version}${RESET}\n\n"
    # Get the folder name if not passed
    if [ -z ${fpath+x} ]; then
        echo -n -e "${WHITE}> Enter the folder name: ${RESET}"
        read fpath
        fname=$(basename "$fpath")
    fi
    # Set up output directory
    current_dir=$(pwd)
    if [ -z ${out_dir+x} ]; then
        out_dir=$(pwd)
    fi
    # Create tmp dir
    create_tmp_dir
    # Get list of subfolders
    get_subfolders
    # Generated pdfs
    generate_pdfs
    # Merge generated pdfs if required
    if [[ "$merge" == "true" ]]; then
        merge_pdf
    fi
    echo -e "\n\n${GREEN_BACK}Successfully generated pdfs!${RESET}"
}
main "$1"
