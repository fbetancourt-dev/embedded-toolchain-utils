# Toolchain Support Check

Detect C and C++ standard support in embedded GCC-based toolchains.

This utility inspects compiler behavior using predefined macros and accepted `-std=` flags to report default language standards, supported standards, detected vendor, target triplet, and a practical C++ recommendation.

---

## 🚀 Features

- Detects the default C++ standard from `__cplusplus`
- Detects the default C standard from `__STDC_VERSION__`
- Checks support for multiple C++ standards:
  - C++98
  - C++03
  - C++11
  - C++14
  - C++17
  - C++20
  - C++23 (`-std=c++2b`)
  - C++26 (`-std=c++2c`)
- Checks support for multiple C standards:
  - C89
  - C90
  - C99
  - C11
  - C17/C18
  - C23 (`-std=c2x`)
- Detects embedded toolchain vendor:
  - STM32
  - NXP
  - ESP32
  - Generic GCC
- Resolves the matching C compiler automatically
- Reports target triplet
- Suggests recommended C++ standard

---

## 📦 Usage

### Auto-detect compiler

```bash
./detect_embedded_toolchain_support.sh
```

### Use a specific compiler

```bash
./detect_embedded_toolchain_support.sh /path/to/compiler
```

Example:

```bash
./detect_embedded_toolchain_support.sh "$(which arm-none-eabi-g++)"
```

---

## 📊 Example Output

```text
====================================
 Embedded Toolchain Support Report
====================================
 Toolchain       : arm-none-eabi
 Vendor          : stm32
 C++ Compiler    : /opt/.../arm-none-eabi-g++
 C Compiler      : /opt/.../arm-none-eabi-gcc
 Version         : arm-none-eabi-g++ (...)
 Target          : arm-none-eabi
 C++ Default     : C++17 (201703L)
 C Default       : C17/C18 (201710L)

 C++ Standard Support
------------------------------------
  C++98    : Supported    (199711L)
  C++03    : Supported    (199711L)
  C++11    : Supported    (201103L)
  C++14    : Supported    (201402L)
  C++17    : Supported    (201703L)
  C++20    : Supported    (202002L)
  C++23    : Supported    (202100L)
  C++26    : Not Supported

 C Standard Support
------------------------------------
  C89      : Supported    (__STDC_VERSION__ not defined)
  C90      : Supported    (__STDC_VERSION__ not defined)
  C99      : Supported    (199901L)
  C11      : Supported    (201112L)
  C17/C18  : Supported    (201710L)
  C23      : Supported    (202000L)
------------------------------------
 Recommended C++ : C++17, C++20, C++23 (experimental)
```

---

## 🧠 How It Works

The script determines support by:

- Testing compiler flags (`-std=c++XX`, `-std=cXX`)
- Inspecting predefined macros:
  - `__cplusplus`
  - `__STDC_VERSION__`

If the compiler accepts the flag and exposes the expected macro, the standard is considered supported.

---

## ⚠️ Support vs Compatibility

This tool detects **compiler support**, not full compatibility.

### ✔ What it detects

- Accepted `-std=` flags
- Macro-reported language version
- Default compiler behavior

### ❌ What it does NOT guarantee

- Full language feature implementation
- Standard library completeness (`<ranges>`, `<format>`)
- ABI compatibility
- RTOS/platform integration

> A compiler accepting a standard flag does NOT guarantee full compatibility with that standard.

---

## 🎯 Why This Matters

Embedded toolchains are often:

- Vendor-modified
- Outdated
- Poorly documented

This tool helps you:

- Validate real compiler capabilities
- Avoid incorrect assumptions
- Decide safely when adopting newer standards

---

## 📌 Notes

- C++23 is tested with `-std=c++2b`
- C++26 is tested with `-std=c++2c`
- C23 is tested with `-std=c2x`
- C89/C90 may not define `__STDC_VERSION__` (expected behavior)
- Vendor detection is heuristic-based

---

## 📁 Structure

```text
toolchain-support-check/
├── detect_embedded_toolchain_support.sh
└── README.md
```

---

## 📄 License

MIT License
