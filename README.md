# 🏥 Patient Vital Signs Sorting and High-Risk Filtering System

> **A 16-bit real-mode x86 assembly application developed for the 8086 CPU architecture, providing low-level clinical triage automation, parallel array sorting, and dynamic color-coded visual feedback without external library dependencies.**

---

## 📺 Project Preview & Interface Architecture

Our system completely eliminates external dependencies like `emu8086.inc` and builds its own pure assembly input/output and formatting engine to interact directly with hardware interrupts.

### 1. Main Triage Console View

==================== M E N U ====================

Display All Patients

Sort Patients by Heart Rate (Descending)

Sort Patients by Temperature (Descending)

Sort Patients by Blood Pressure (Descending)

Filter and Display High-Risk Patients Only

Input New Patient Dataset

Exit System
Enter your choice (1-7): _


### 2. Clinical Data Visualization Matrix
The console applies high-contrast color attributes to provide healthcare workers with immediate visual feedback regarding patient priority:
* **Normal Status:** Rendered in **Light Green Text on Blue Background (`BL = 1Ah`)**
* **HIGH RISK Status:** Rendered in **Light Red Text on Blue Background (`BL = 1Ch`)**

---

## 🚀 Core Project Objectives

1. **Automated Clinical Triage Logic**
   * Evaluates multi-parametric patient vital signs against clinical reference ranges in real time, dynamically labeling patient profiles into specific risk layers.
2. **Responsive Keyboard-Driven User Interface**
   * Establishes a flicker-free, menu-driven command interface utilizing BIOS keyboard services (`INT 16h / AH=00h`) to achieve latency-free terminal navigation.
3. **Synchronized Multi-Type Parallel Array Sorting**
   * Runs advanced bubble sort routines capable of concurrently reorganizing mixed-width data arrays while maintaining perfect structural pointer alignment across records.
4. **8086 Fixed-Point Arithmetic Adaptation**
   * Overcomes x86 fractional division processing constraints by scaling core temperatures by 10 (storing `36.5` as integer `365`) and converting integers to custom ASCII blocks for decimal rendering.

---

## 📐 Data Structure & Memory Topology

Since the 8086 assembly language lacks native objects or structs, all patient data profiles are maintained concurrently across parallel memory sequences using unified index matching ($i$).

### Parallel Memory Allocation Mapping
* **Data Segment (`.data`) Configuration:** Small Memory Model (`.model small`)
* **Stack Buffer Allocation:** 256 Bytes (`.stack 100h`)

| Data Token | Allocation Width | Physical Purpose | Standard Reference Window |
| :--- | :--- | :--- | :--- |
| **`PATIENT_ID`** | 8-bit Unsigned (`DB`) | Unique Patient Identifier | `1 - 255` |
| **`HEART_RATE`** | 8-bit Unsigned (`DB`) | Pulse Frequency Monitoring | `60 - 100 bpm` (Normal) |
| **`TEMPERATURE`**| 16-bit Unsigned (`DW`) | Fixed-point Body Temperature | `360 - 379` ($36.0^\circ C - 37.9^\circ C$) |
| **`BLOOD_PRESSURE`**| 8-bit Unsigned (`DB`) | Systolic Blood Pressure | `90 - 139 mmHg` (Normal) |
| **`N`** | 16-bit Unsigned (`DW`) | Count of active patients | `1 - 100` Records |

> **Structural Engineering Note:** A 16-bit Word array (`DW`) is strictly required for `TEMPERATURE` because the fixed-point value of high fevers (e.g., $38.2^\circ C \rightarrow 382$) overflows the physical 8-bit unsigned integer allocation limit (`255`).

---

## 💻 Deep-Dives: Core Subroutine Implementation

### ⚙️ Clinical Risk Assessment Engine
An individual is instantly tagged as `HIGH RISK` if even a single vital metric drifts beyond the clinical boundaries:

$$60 \le \text{HR} \le 100 \quad \land \quad 90 \le \text{BP} \le 139 \quad \land \quad 360 \le \text{TEMP} \le 379$$

```assembly
CHECK_RISK PROC NEAR
    ; Input: SI = Patient index
    ; Output: AL = 0 if normal, 1 if high risk
    
    ; Check Heart Rate
    MOV AL, HEART_RATE[SI]
    CMP AL, 60
    JB  RISK_HIGH
    CMP AL, 100
    JA  RISK_HIGH
    
    ; Check Blood Pressure
    MOV AL, BLOOD_PRESSURE[SI]
    CMP AL, 90
    JB  RISK_HIGH
    CMP AL, 139
    JA  RISK_HIGH
    
    ; Check Temperature (DW array, offset SI * 2)
    MOV DI, SI
    SHL DI, 1
    MOV AX, TEMPERATURE[DI]
    CMP AX, 360 
    JB  RISK_HIGH
    CMP AX, 379 
    JA  RISK_HIGH
    
    MOV AL, 0
    RET
RISK_HIGH:
    MOV AL, 1
    RET
CHECK_RISK ENDP
🛠️ Technical Challenges & System Engineering
The Problem
Simultaneously indexing 8-bit byte arrays (PATIENT_ID, HEART_RATE, BLOOD_PRESSURE) alongside a 16-bit word array (TEMPERATURE) inside a standard loops triggers index collisions if pointer scaling mismatch occurs.

**The Solution**

Maintained the loop counter I as the uniform base index. When accessing 8-bit byte blocks, unit increments via index registers work natively. When approaching the 16-bit TEMPERATURE sector, the pointer address is isolated, mapped to DI, and shifted left by 1 bit (SHL DI, 1) to accurately parse the double-byte memory block boundary.

**The Problem**

Standard 8086 conditional branching operations (such as JE, JNZ) are hardware-limited to a signed 8-bit displacement offset mapping threshold (−128 to +127 bytes from the instruction pointer). As our triage classification logic expanded, compilation failed with Relative jump out of range errors.

**The Solution**

Implemented a modular compiler optimization technique called "Logical JMP Trampolining". By inverting the conditional testing gates (e.g., swapping a match gate to a mismatch escape gate), long distance routing is handed off to unconditional JMP commands, which safely support a massive 16-bit relative scaling offset across wide segments.

**The Problem**

The legacy ASCII horizontal tab character (09h) is interpreted by standard PC BIOS video interrupts as a graphic circular glyph (◦ / Code Page 437 code 9) rather than a spatial spacing instruction under default teletype character services.

**The Solution**
Engineered a custom mathematical layout formatting procedure (PRINT_TAB) that overrides the glitch. The engine queries the current hardware cursor coordinates in real time (INT 10h / AH=03h), extracts the current column profile DL, and calculates the relative distance needed to touch the nearest modular 8-column tab horizon:

Spaces to Print=8−(DL(mod8))
The layout then loops and shoots out the precise quantity of empty standard space string blocks (20h) to guarantee clean, unshifted columns.

⚙️ How to Build, Mount, and Run
Prerequisites
To compile and emulate this 16-bit real-mode system architecture on modern operating systems (macOS/Windows/Linux), ensure you have:

DOSBox x86 Emulator Emulator Platform

Turbo Assembler (TASM 4.1) & Turbo Link (TLINK) compiler binaries

Assembly Execution Roadmap
Place your patient_vitals.asm into your local directory, mount the workspace path inside your active DOSBox container environment, and enter the following operational commands:

Bash
# Step 1: Compile the assembly source code into an object module
tasm patient_vitals.asm

# Step 2: Link the relocatable object file into a DOS real-mode executable
tlink patient_vitals.obj

# Step 3: Initialize the monitoring application console
patient_vitals.exe
🔬 Verified Clinical Evaluation Dataset
Input the following test profile vectors to witness full software diagnostic execution, threshold filtering, and parallel bubble sorting mechanics:

Patient Profile #1: ID = 11 | HR = 75 | TEMP = 365 (36.5 ∘C) | BP = 120 → Expected Status: Normal

Patient Profile #2: ID = 22 | HR = 110 | TEMP = 382 (38.2 ∘C) | BP = 145 → Expected Status: HIGH RISK

Patient Profile #3: ID = 33 | HR = 55 | TEMP = 358 (35.8 ∘C) | BP = 85 → Expected Status: HIGH RISK
