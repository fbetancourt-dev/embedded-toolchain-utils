# Embedded Toolchain Utils

A collection of small but practical tools for embedded engineers to inspect, validate, and better understand their development environments.

---

## 🚀 Available Tools

### 🔧 Toolchain Support Check

Detects compiler support for C and C++ standards in embedded GCC-based toolchains.

**Features:**
- Detects default C and C++ standards
- Verifies support for multiple standard flags (`-std=c++XX`, `-std=cXX`)
- Inspects compiler macros (`__cplusplus`, `__STDC_VERSION__`)
- Identifies toolchain vendor (STM32, ESP32, NXP, generic)
- Works with common embedded GCC toolchains:
  - `arm-none-eabi`
  - `xtensa-esp32`
  - `xtensa-esp32s3`
  - `riscv32-esp`

👉 See: [toolchain-support-check](./toolchain-support-check)

---

## 🎯 Purpose

In embedded systems, what a compiler *accepts* is not always what it fully *supports* in production.

These tools help:
- Audit toolchain capabilities quickly
- Avoid incorrect assumptions about language support
- Make informed decisions before adopting newer C/C++ standards
- Compare IDE-bundled toolchains vs system toolchains

---

## ⚠️ Important Note: Support vs Compatibility

These tools detect **compiler support**, not full compatibility.

### ✔ What is detected
- Flag acceptance (`-std=c++20`, `-std=c2x`, etc.)
- Macro-level detection (`__cplusplus`, `__STDC_VERSION__`)
- Default compiler behavior

### ❌ What is NOT guaranteed
- Full language feature implementation
- Standard library completeness (`<ranges>`, `<format>`, etc.)
- ABI compatibility
- RTOS or platform integration

> A compiler accepting a standard flag does NOT guarantee full compatibility with that standard.

---

## 📦 Installation

Clone the repository:

```bash
git clone https://github.com/<your-username>/embedded-toolchain-utils.git
cd embedded-toolchain-utils
