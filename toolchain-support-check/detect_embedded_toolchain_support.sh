#!/usr/bin/env bash
set -euo pipefail

map_cpp_standard() {
    local value="${1:-unknown}"

    case "$value" in
        199711L) echo "C++98/C++03" ;;
        201103L) echo "C++11" ;;
        201402L) echo "C++14" ;;
        201703L) echo "C++17" ;;
        202002L) echo "C++20" ;;
        202100L|202302L) echo "C++23" ;;
        unknown|"") echo "unknown" ;;
        *)
            if [[ "$value" =~ ^202[4-9][0-9][0-9]L$ ]] || [[ "$value" =~ ^20[3-9][0-9][0-9][0-9]L$ ]]; then
                echo "C++26 (draft)"
            else
                echo "unknown ($value)"
            fi
            ;;
    esac
}

map_c_standard() {
    local value="${1:-unknown}"

    case "$value" in
        199409L) echo "C90/C95" ;;
        199901L) echo "C99" ;;
        201112L) echo "C11" ;;
        201710L) echo "C17/C18" ;;
        202000L|202311L) echo "C23" ;;
        unknown|"") echo "unknown" ;;
        *)
            echo "unknown ($value)"
            ;;
    esac
}

print_usage() {
    cat <<'EOF'
Usage:
  ./detect_embedded_toolchain_compatibility.sh [path_to_cpp_compiler]

Examples:
  ./detect_embedded_toolchain_compatibility.sh
  ./detect_embedded_toolchain_compatibility.sh /opt/st/.../arm-none-eabi-g++
  ./detect_embedded_toolchain_compatibility.sh "$(which arm-none-eabi-g++)"
EOF
}

detect_default_cpp_compiler() {
    if command -v arm-none-eabi-g++ >/dev/null 2>&1; then
        command -v arm-none-eabi-g++
        return 0
    elif command -v xtensa-esp32-elf-g++ >/dev/null 2>&1; then
        command -v xtensa-esp32-elf-g++
        return 0
    elif command -v xtensa-esp32s3-elf-g++ >/dev/null 2>&1; then
        command -v xtensa-esp32s3-elf-g++
        return 0
    elif command -v riscv32-esp-elf-g++ >/dev/null 2>&1; then
        command -v riscv32-esp-elf-g++
        return 0
    fi

    return 1
}

resolve_c_compiler() {
    local cpp_compiler="$1"
    local c_compiler=""

    if [[ "$cpp_compiler" == *"g++" ]]; then
        c_compiler="${cpp_compiler%g++}gcc"
    elif [[ "$cpp_compiler" == *"clang++" ]]; then
        c_compiler="${cpp_compiler%clang++}clang"
    fi

    if [[ -n "$c_compiler" && -x "$c_compiler" ]]; then
        printf '%s\n' "$c_compiler"
        return 0
    fi

    return 1
}

detect_vendor() {
    local compiler_path="$1"
    local compiler_version="$2"

    local vendor="unknown"
    local path_lower
    local version_lower

    path_lower="$(printf '%s' "$compiler_path" | tr '[:upper:]' '[:lower:]')"
    version_lower="$(printf '%s' "$compiler_version" | tr '[:upper:]' '[:lower:]')"

    if [[ "$path_lower" == *"stm32cubeide"* ]] || [[ "$path_lower" =~ (^|/)st(/|$) ]]; then
        vendor="stm32"
    elif [[ "$path_lower" == *"nxp"* ]] || [[ "$path_lower" == *"s32ds"* ]]; then
        vendor="nxp"
    elif [[ "$path_lower" == *"espressif"* ]] || [[ "$path_lower" == *"esp32"* ]] || [[ "$path_lower" == *"xtensa-esp"* ]] || [[ "$path_lower" == *"riscv32-esp"* ]]; then
        vendor="esp32"
    elif grep -q "stm32" <<< "$version_lower"; then
        vendor="stm32"
    elif grep -q "nxp" <<< "$version_lower"; then
        vendor="nxp"
    elif grep -q "espressif" <<< "$version_lower" || grep -q "esp32" <<< "$version_lower"; then
        vendor="esp32"
    else
        vendor="generic"
    fi

    printf '%s\n' "$vendor"
}

main() {
    local cpp_compiler="${1:-}"
    local c_compiler=""
    local toolchain=""
    local vendor=""
    local version_line=""
    local triplet="unknown"

    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        print_usage
        exit 0
    fi

    if [[ -z "$cpp_compiler" ]]; then
        if ! cpp_compiler="$(detect_default_cpp_compiler)"; then
            echo "No embedded C++ compiler found in PATH"
            exit 1
        fi
    fi

    if [[ ! -x "$cpp_compiler" ]]; then
        echo "Compiler path is not executable:"
        echo "  $cpp_compiler"
        exit 1
    fi

    version_line="$("$cpp_compiler" --version | head -n1)"
    vendor="$(detect_vendor "$cpp_compiler" "$version_line")"
    triplet="$("$cpp_compiler" -dumpmachine 2>/dev/null || echo unknown)"

    if [[ "$cpp_compiler" == *"arm-none-eabi-g++" ]]; then
        toolchain="arm-none-eabi"
    elif [[ "$cpp_compiler" == *"xtensa-esp32-elf-g++" ]]; then
        toolchain="xtensa-esp32"
    elif [[ "$cpp_compiler" == *"xtensa-esp32s3-elf-g++" ]]; then
        toolchain="xtensa-esp32s3"
    elif [[ "$cpp_compiler" == *"riscv32-esp-elf-g++" ]]; then
        toolchain="riscv32-esp"
    else
        toolchain="$(basename "$cpp_compiler")"
    fi

    if ! c_compiler="$(resolve_c_compiler "$cpp_compiler")"; then
        echo "Could not locate matching C compiler for:"
        echo "  $cpp_compiler"
        exit 1
    fi

    local cpp_default_value
    local cpp_default_name
    cpp_default_value="$("$cpp_compiler" -dM -E -x c++ /dev/null 2>/dev/null | awk '/__cplusplus/ {print $3; exit}')"
    [[ -n "$cpp_default_value" ]] || cpp_default_value="unknown"
    cpp_default_name="$(map_cpp_standard "$cpp_default_value")"

    local c_default_value
    local c_default_name
    c_default_value="$("$c_compiler" -dM -E -x c /dev/null 2>/dev/null | awk '/__STDC_VERSION__/ {print $3; exit}')"
    [[ -n "$c_default_value" ]] || c_default_value="unknown"
    c_default_name="$(map_c_standard "$c_default_value")"

    declare -A cpp_labels
    declare -A cpp_flags
    declare -A cpp_supported
    declare -A cpp_values

    cpp_labels["98"]="C++98"
    cpp_labels["03"]="C++03"
    cpp_labels["11"]="C++11"
    cpp_labels["14"]="C++14"
    cpp_labels["17"]="C++17"
    cpp_labels["20"]="C++20"
    cpp_labels["2b"]="C++23"
    cpp_labels["2c"]="C++26"

    cpp_flags["98"]="-std=c++98"
    cpp_flags["03"]="-std=c++03"
    cpp_flags["11"]="-std=c++11"
    cpp_flags["14"]="-std=c++14"
    cpp_flags["17"]="-std=c++17"
    cpp_flags["20"]="-std=c++20"
    cpp_flags["2b"]="-std=c++2b"
    cpp_flags["2c"]="-std=c++2c"

    local cpp_standards=("98" "03" "11" "14" "17" "20" "2b" "2c")
    local key=""
    local value=""

    for key in "${cpp_standards[@]}"; do
        if value="$("$cpp_compiler" "${cpp_flags[$key]}" -dM -E -x c++ /dev/null 2>/dev/null | awk '/__cplusplus/ {print $3; exit}')" && [[ -n "$value" ]]; then
            cpp_supported["$key"]="Supported"
            cpp_values["$key"]="$value"
        else
            cpp_supported["$key"]="Not Supported"
            cpp_values["$key"]=""
        fi
    done

    declare -A c_labels
    declare -A c_flags
    declare -A c_supported
    declare -A c_values

    c_labels["89"]="C89"
    c_labels["90"]="C90"
    c_labels["99"]="C99"
    c_labels["11"]="C11"
    c_labels["17"]="C17/C18"
    c_labels["23"]="C23"

    c_flags["89"]="-std=c89"
    c_flags["90"]="-std=c90"
    c_flags["99"]="-std=c99"
    c_flags["11"]="-std=c11"
    c_flags["17"]="-std=c17"
    c_flags["23"]="-std=c2x"

    local c_standards=("89" "90" "99" "11" "17" "23")

    for key in "${c_standards[@]}"; do
        if value="$("$c_compiler" "${c_flags[$key]}" -dM -E -x c /dev/null 2>/dev/null | awk '/__STDC_VERSION__/ {print $3; exit}')" && [[ -n "$value" ]]; then
            c_supported["$key"]="Supported"
            c_values["$key"]="$value"
        else
            if [[ "$key" == "89" || "$key" == "90" ]]; then
                if "$c_compiler" "${c_flags[$key]}" -dM -E -x c /dev/null >/dev/null 2>&1; then
                    c_supported["$key"]="Supported"
                    c_values["$key"]="__STDC_VERSION__ not defined"
                else
                    c_supported["$key"]="Not Supported"
                    c_values["$key"]=""
                fi
            else
                c_supported["$key"]="Not Supported"
                c_values["$key"]=""
            fi
        fi
    done

    echo
    echo "===================================="
    echo " Embedded Toolchain Compatibility Report"
    echo "===================================="
    echo " Toolchain       : $toolchain"
    echo " Vendor          : $vendor"
    echo " C++ Compiler    : $cpp_compiler"
    echo " C Compiler      : $c_compiler"
    echo " Version         : $version_line"
    echo " Target          : $triplet"
    echo " C++ Default     : $cpp_default_name ($cpp_default_value)"
    echo " C Default       : $c_default_name ($c_default_value)"
    echo

    echo " C++ Standard Support"
    echo "------------------------------------"
    for key in "${cpp_standards[@]}"; do
        if [[ "${cpp_supported[$key]}" == "Supported" ]]; then
            printf "  %-8s : %-13s (%s)\n" "${cpp_labels[$key]}" "${cpp_supported[$key]}" "${cpp_values[$key]}"
        else
            printf "  %-8s : %-13s\n" "${cpp_labels[$key]}" "${cpp_supported[$key]}"
        fi
    done
    echo

    echo " C Standard Support"
    echo "------------------------------------"
    for key in "${c_standards[@]}"; do
        if [[ "${c_supported[$key]}" == "Supported" ]]; then
            printf "  %-8s : %-13s (%s)\n" "${c_labels[$key]}" "${c_supported[$key]}" "${c_values[$key]}"
        else
            printf "  %-8s : %-13s\n" "${c_labels[$key]}" "${c_supported[$key]}"
        fi
    done
    echo "------------------------------------"

    local recommendation=""
    if [[ "${cpp_supported[17]}" == "Supported" ]]; then
        recommendation="C++17"
    fi
    if [[ "${cpp_supported[20]}" == "Supported" ]]; then
        recommendation+=", C++20"
    fi
    if [[ "${cpp_supported[2b]}" == "Supported" ]]; then
        recommendation+=", C++23 (experimental)"
    fi
    if [[ "${cpp_supported[2c]}" == "Supported" ]]; then
        recommendation+=", C++26 (experimental)"
    fi

    echo " Recommended C++ : ${recommendation#, }"
    echo
}

main "$@"
