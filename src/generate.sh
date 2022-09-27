#!/usr/bin/bash


#################### SCRIPT START ####################


# ----------------- Script version -----------------#
Version="v0.1"


# ------------------ Colors codes ------------------#
WHITE="\033[1;37m"
YELLOW="\033[1;93m"
GREEN="\033[1;92m"
RED="\033[1;31m"
CYAN_BACK="\033[1;46m"
GREEN_BACK="\033[1;102m"
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
        -m|--merge)
            merge="true"
            shift
            ;;
    esac
done


#-------------------- Functions --------------------#
check_dependencies() {
    declare -a depends=("convert" "pdftools")
    for pack in "${depends[@]}"; do
        CHCK=$(command -v "$pack" &> /dev/null)
        if ! $CHCK; then
            echo -e "   ${RED}[WARNING!] Package $pack not found!${RESET}"
            exit 1
        fi
    done
}

create_tmp_dir() {
    chtmp="$fname-generated"
    if [ -d "$chtmp" ]; then
        echo -e "  ${YELLOW}[!] Removing existing pdfs in $chtmp!${RESET}"
        rm -rf "$chtmp"
    fi
    mkdir "$chtmp"
}

get_subfolders() {
    echo -e "${WHITE}> Scanning for chapter folders...${RESET}"
    folders=$(find "$fpath"/ -maxdepth 1 -mindepth 1 -type d | sort -nk1.8)
    folders_count=$(echo "$folders" | wc -l)
    echo -e "   ${YELLOW}[!] Found $folders_count sub-folders inside $fname${RESET}\n"
}

generate_pdfs() {
    for i in $folders; do
        IFS='/'
        read -a chstr <<< "$i"
        echo -e "  ${GREEN}[+]${RESET} Generating pdf for ${chstr[1]}"
        convert "$i/*.jpg" "$chtmp/${chstr[1]}.pdf"
    done
}

merge_pdf() {
    echo -e "\n${WHITE}> Merging chapters into single pdf...${RESET}"
	pdftools merge -o "$fname.pdf" "$chtmp"/*.pdf
}

main() {
    # Check if the required packages are installed
    check_dependencies
    # Show heading
    echo -e "${CYAN_BACK}Gen-pdf.sh - ${Version}${RESET}"
    # Get the folder name if not passed
    if [ -z ${fpath+x} ]; then
        read -p -e "${WHITE}> Enter the folder name: ${RESET}" fpath
        fname=$(basename "$fpath")
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
