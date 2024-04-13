// ------------------------------------------------------------
// Armv8/9-A PACBTI Example
//
// Basic Vectors, PACBTI, MMU, and caches initialization
//
// Exits in EL1 AArch64
//
// Copyright (c) 2022 Arm Limited (or its affiliates). All rights reserved.
// Use, modification and redistribution of this file is subject to your possession of a
// valid End User License Agreement for the Arm Product of which these examples are part of 
// and your compliance with all applicable terms and conditions of such licence agreement.
// ------------------------------------------------------------

#include "v8_mmu.h"
#include "v8_system.h"


    .section StartUp, "ax"
    .balign 4
    .cfi_sections .debug_frame  // put stack frame info into .debug_frame instead of .eh_frame

    .global el1_vectors
    .global el2_vectors
    .global el3_vectors

    .global InvalidateUDCaches
    .global ZeroBlock

    .global __main

    .global Image$$EXEC$$RO$$Base
    .global Image$$TTB0_L1$$ZI$$Base
    .global Image$$TTB0_L2_RAM$$ZI$$Base
    .global Image$$TTB0_L2_PERIPH$$ZI$$Base
    .global Image$$TOP_OF_RAM$$ZI$$Base
    .global Image$$ARM_LIB_STACK$$ZI$$Limit
    .global Image$$EL3_STACKS$$ZI$$Limit
    // use separate stack and heap, as assumed by scatter.scat
    .global __use_two_region_memory


  section RESET:CODE:NOROOT(2)
  PUBLIC  Vectors
    .fill 0x400, 1, 0

// ------------------------------------------------------------

    .global start64
    .type start64, "function"
start64:
    // Extract the core number from MPIDR_EL1
    bl GetCPUID

    // If run on a multi-core system, put any secondary cores to sleep
    cbz x0, core0_only
loop_wfi:
    dsb SY      // Clear all pending data accesses
    wfi         // Go to sleep
    b loop_wfi

core0_only:

    //
    // program the VBARs
    //
    ldr x1, =el1_vectors
    msr VBAR_EL1, x1

    ldr x1, =el2_vectors
    msr VBAR_EL2, x1

    ldr x1, =el3_vectors
    msr VBAR_EL3, x1


    // GIC-500 comes out of reset in GICv2 compatibility mode - first set
    // system register enables for all relevant exception levels, and
    // select GICv3 operating mode
    //
    msr SCR_EL3, xzr  // Ensure NS bit is initially clear, so secure copy of ICC_SRE_EL1 can be configured
    isb

    mov x0, #15
    msr ICC_SRE_EL3, x0
    isb
    msr ICC_SRE_EL1, x0 // Secure copy of ICC_SRE_EL1

    //
    // set lower exception levels as non-secure, with no access
    // back to EL2 or EL3, and are AArch64 capable
    //
    mov x3, #(SCR_EL3_RW  | \
              SCR_EL3_SMD | \
              SCR_EL3_NS)      // Set NS bit, to access Non-secure registers
    msr SCR_EL3, x3
    isb

    mov x0, #15
    msr ICC_SRE_EL2, x0
    isb
    msr ICC_SRE_EL1, x0 // Non-secure copy of ICC_SRE_EL1


    //
    // no traps or VM modifications from the Hypervisor, EL1 is AArch64
    //
    mov x2, #HCR_EL2_RW
    msr HCR_EL2, x2

    //
    // VMID is still significant, even when virtualisation is not
    // being used, so ensure VTTBR_EL2 is properly initialised
    //
    msr VTTBR_EL2, xzr

    //
    // VMPIDR_EL2 holds the value of the Virtualization Multiprocessor ID. This is the value returned by Non-secure EL1 reads of MPIDR_EL1.
    //  VPIDR_EL2 holds the value of the Virtualization Processor ID. This is the value returned by Non-secure EL1 reads of MIDR_EL1.
    // Both of these registers are architecturally UNKNOWN at reset, and so they must be set to the correct value
    // (even if EL2/virtualization is not being used), otherwise non-secure EL1 reads of MPIDR_EL1/MIDR_EL1 will return garbage values.
    // This guarantees that any future reads of MPIDR_EL1 and MIDR_EL1 from Non-secure EL1 will return the correct value.
    //
    mrs x0, MPIDR_EL1
    msr VMPIDR_EL2, x0
    mrs x0, MIDR_EL1
    msr VPIDR_EL2, x0

    //
    // neither EL3 nor EL2 trap floating point or accesses to CPACR
    //
    msr CPTR_EL3, xzr
    msr CPTR_EL2, xzr

    //
    // SCTLR_ELx may come out of reset with UNKNOWN values so we will
    // set the fields to 0 except, possibly, the endianess field(s).
    // Note that setting SCTLR_EL2 or the EL0 related fields of SCTLR_EL1
    // is not strictly needed, since we're never in EL2 or EL0
    //
#ifdef __ARM_BIG_ENDIAN
    mov x0, #(SCTLR_ELx_EE | SCTLR_EL1_E0E)
#else
    mov x0, #0
#endif
    msr SCTLR_EL3, x0
    msr SCTLR_EL2, x0
    msr SCTLR_EL1, x0

    //
    // That's the last of the control settings for now
    //
    // Note: no ISB after all these changes, as registers won't be
    // accessed until after an exception return, which is itself a
    // context synchronisation event
    //

    //
    // Setup some EL3 stack space, ready for calling some subroutines, below.
    //
    ldr x0, =Image$$EL3_STACKS$$ZI$$Limit
    mov sp, x0


    //
    // Check whether Pointer Authentication is implemented
    //
    MRS X0, ID_AA64ISAR1_EL1
    ANDS x1, x0, #0xF00 // extract API bits [11:8]
    B.NE api_yes
    ANDS x1, x0, #0xF0 // extract APA bits [7:4]
    B.NE apa_yes

die:
    B . // Endless loop if PAC or BTI is not implemented

apa_yes:
api_yes:

    //
    // Check whether Branch Target Identification is implemented
    //
    MRS X0, ID_AA64PFR1_EL1
    ANDS x1, x0, #0xF // extract BT bits [3:0]
    B.EQ die


    // Disable all SVE and SIMD traps by setting CPTR_EL3.EZ bit [8] and clearing CPTR_EL3.TFP bit [10]
    MRS x0, CPTR_EL3
    BIC x0, x0, #(1<<10)
    ORR x0, x0, #(1<<8)
    MSR CPTR_EL3, x0
    ISB

    // Set up the PAC signing keys.
    // For security, a random encryption key should be used on every boot.
    // Lacking that, for testing purposes, a fixed random-like one is used here.

    LDR x0,=0xfb4211e7a72b4c6d
    MSR APIAKeyHi_EL1, x0
    LDR x0,=0xeea2fc6fd95e20dd
    MSR APIAKeyLo_EL1, x0
    LDR x0,=0xc23102c705b1c5a1
    MSR APIBKeyHi_EL1, x0
    LDR x0,=0x6582a26991336de4
    MSR APIBKeyLo_EL1, x0

    LDR x0,=0xc7202e7f661ce52b
    MSR APDAKeyHi_EL1, x0
    LDR x0,=0xdd037834858c3bfe
    MSR APDAKeyLo_EL1, x0
    LDR x0,=0xb1f60ef6f51bc635
    MSR APDBKeyHi_EL1, x0
    LDR x0,=0x812a85f8654bd217
    MSR APDBKeyLo_EL1, x0

    LDR x0,=0xa76590ccf81c5a4b
    MSR APGAKeyHi_EL1, x0
    LDR x0,=0x9a2bf06575f29b1a
    MSR APGAKeyLo_EL1, x0

    MRS x0, SCR_EL3
    ORR x0, x0, #(1 << 17) // Disable traps on PAC instns in EL2 and lower by setting SCR_EL3_API
    MSR SCR_EL3, x0

    MRS x0, HCR_EL2
    ORR x0, x0, #(1 << 41) // Disable traps on PAC instns in EL1 by setting HCR_EL2_API
    MSR HCR_EL2, x0

    //
    // Set up EL1 entry point and "dummy" exception return information,
    // then perform exception return to enter EL1
    //
    .global drop_to_el1
drop_to_el1:
    adr x1, el1_entry_aarch64
    msr ELR_EL3, x1
    mov x1, #(AARCH64_SPSR_EL1h | \
              AARCH64_SPSR_F  | \
              AARCH64_SPSR_I  | \
              AARCH64_SPSR_A)
    msr SPSR_EL3, x1
    eret



// ------------------------------------------------------------
// EL1 - Common start-up code
// ------------------------------------------------------------

    .global el1_entry_aarch64
    .type el1_entry_aarch64, "function"
el1_entry_aarch64:

    // Enable Pointer Authentication for both instruction and data accesses, for both keys
    MRS x0, SCTLR_EL1
    ORR x0, x0, #(1<<13)  // EnDB
    ORR x0, x0, #(1<<27)  // EnDA
    ORR x0, x0, #(1<<30)  // EnIB
    ORR x0, x0, #(1<<31)  // EnIA
    MSR SCTLR_EL1, x0
    ISB

    //
    // Now we're in EL1, setup the application stack
    //
    ldr x0, =Image$$ARM_LIB_STACK$$ZI$$Limit
    mov sp, x0

    //
    // Enable floating point
    //
    mov x0, #CPACR_EL1_FPEN
    msr CPACR_EL1, x0

    //
    // Invalidate caches and TLBs for all stage 1
    // translations used at EL1
    //
    // Cortex-A processors automatically invalidate their caches on reset
    // (unless suppressed with the DBGL1RSTDISABLE or L2RSTDISABLE pins).
    // It is therefore not necessary for software to invalidate the caches 
    // on startup, however, this is done here in case of a warm reset.
    bl  InvalidateUDCaches
    tlbi VMALLE1


    //
    // Set TTBR0 Base address
    //
    // The CPUs share one set of translation tables that are
    // generated by CPU0 at run-time
    //
    // TTBR1_EL1 is not used in this example
    //
    ldr x1, =Image$$TTB0_L1$$ZI$$Base
    msr TTBR0_EL1, x1


    //
    // Set up memory attributes
    //
    // These equate to:
    //
    // 0 -> 0b01000100 = 0x00000044 = Normal, Inner/Outer Non-Cacheable
    // 1 -> 0b11111111 = 0x0000ff00 = Normal, Inner/Outer WriteBack Read/Write Allocate
    // 2 -> 0b00000100 = 0x00040000 = Device-nGnRE
    //
    mov  x1, #0xff44
    movk x1, #4, LSL #16    // equiv to: movk x1, #0x0000000000040000
    msr MAIR_EL1, x1


    //
    // Set up TCR_EL1
    //
    // We're using only TTBR0 (EPD1 = 1), and the page table entries:
    //  - are using an 8-bit ASID from TTBR0
    //  - have a 4K granularity (TG0 = 0b00)
    //  - are outer-shareable (SH0 = 0b10)
    //  - are using Inner & Outer WBWA Normal memory ([IO]RGN0 = 0b01)
    //  - map
    //      + 32 bits of VA space (T0SZ = 0x20)
    //      + into a 32-bit PA space (IPS = 0b000)
    //
    //     36   32   28   24   20   16   12    8    4    0
    //  -----+----+----+----+----+----+----+----+----+----+
    //       |    |    |OOII|    |    |    |OOII|    |    |
    //    TT |    |    |RRRR|E T |   T|    |RRRR|E T |   T|
    //    BB | I I|TTSS|GGGG|P 1 |   1|TTSS|GGGG|P 0 |   0|
    //    IIA| P P|GGHH|NNNN|DAS |   S|GGHH|NNNN|D S |   S|
    //    10S| S-S|1111|1111|11Z-|---Z|0000|0000|0 Z-|---Z|
    //
    //    000 0000 0000 0000 1000 0000 0010 0101 0010 0000
    //
    //                    0x    8    0    2    5    2    0
    //
    // Note: the ISB is needed to ensure the changes to system
    //       context are before the write of SCTLR_EL1.M to enable
    //       the MMU. It is likely on a "real" implementation that
    //       this setup would work without an ISB, due to the
    //       amount of code that gets executed before enabling the
    //       MMU, but that would not be architecturally correct.
    //
    ldr x1, =0x0000000000802520
    msr TCR_EL1, x1
    isb

    //
    // Generate TTBR0 L1
    //
    // at 4KB granularity, 32-bit VA space, table lookup starts at
    // L1, with 1GB regions
    //
    // we are going to create entries pointing to L2 tables for a
    // couple of these 1GB regions, the first of which is the
    // RAM on the target system - get the table addresses and
    // start by emptying out the L1 page tables (4 entries at L1
    // for a 4K granularity)
    //
    // x21 = address of L1 tables
    //
    ldr x21, =Image$$TTB0_L1$$ZI$$Base
    mov x0, x21
    mov x1, #(4 << 3)
    bl  ZeroBlock

    //
    // time to start mapping the RAM regions - clear out the
    // L2 tables and point to them from the L1 tables
    //
    // x22 = address of L2 tables, needs to be remembered in case
    //       we want to re-use the tables for mapping peripherals
    //
    ldr x22, =Image$$TTB0_L2_RAM$$ZI$$Base
    mov x1, #(512 << 3)
    mov x0, x22
    bl  ZeroBlock

    //
    // Get the start address of RAM (the EXEC region) into x4
    // and calculate the offset into the L1 table (1GB per region,
    // max 4GB)
    //
    // x23 = L1 table offset, saved for later comparison against
    //       peripheral offset
    //
    ldr x4, =Image$$EXEC$$RO$$Base
    ubfx x23, x4, #30, #2

    orr x1, x22, #TT_S1_ATTR_PAGE
    str x1, [x21, x23, lsl #3]

    //
    // we've already used the RAM start address in x4 - we now need
    // to get this in terms of an offset into the L2 page tables,
    // where each entry covers 2MB
    //
    ubfx x2, x4, #21, #9

    //
    // TOP_OF_RAM in the scatter file marks the end of the
    // Execute region in RAM: convert the end of this region to an
    // offset too, being careful to round up, then calculate the
    // number of entries to write
    //
    ldr x5, =Image$$TOP_OF_RAM$$ZI$$Base
    sub  x3, x5, #1
    ubfx x3, x3, #21, #9
    add  x3, x3, #1
    sub  x3, x3, x2

    //
    // set x1 to the required page table attributes, then orr
    // in the start address (modulo 2MB)
    //
    // L2 tables in our configuration cover 2MB per entry - map
    // memory as Shared, Normal WBWA (MAIR[1]) with a flat
    // VA->PA translation
    //
    bic x4, x4, #((1 << 21) - 1)
    ldr x1, =(TT_S1_ATTR_BLOCK | \
             (1 << TT_S1_ATTR_MATTR_LSB) | \
              TT_S1_ATTR_NS | \
              TT_S1_ATTR_AP_RW_PL1 | \
              TT_S1_ATTR_SH_INNER | \
              TT_S1_ATTR_AF | \
              TT_S1_ATTR_nG | \
              TT_S1_ATTR_GP)  // Guarded Page set to enable Branch Target Identification (BTI) support
    orr x1, x1, x4

    //
    // factor the offset into the page table address and then write
    // the entries
    //
    add x0, x22, x2, lsl #3

loop1:
    subs x3, x3, #1
    str x1, [x0], #8
    add x1, x1, #0x200, LSL #12    // equiv to add x1, x1, #(1 << 21)  // 2MB per entry
    bne loop1


    //
    // issue a barrier to ensure all table entry writes are complete
    //
    dsb ish

    //
    // Enable the MMU.  Caches will be enabled later, after scatterloading.
    //
    mrs x1, SCTLR_EL1
    orr x1, x1, #SCTLR_ELx_M
    bic x1, x1, #SCTLR_ELx_A // Disable alignment fault checking.  To enable, change bic to orr
    msr SCTLR_EL1, x1
    isb

    //
    // Branch to C library init code
    //
    b  __main


// ------------------------------------------------------------

// AArch64 Arm C library startup add-in:

// The Arm Architecture Reference Manual for Armv8-A states:
//
//     Instruction accesses to Non-cacheable Normal memory can be held in instruction caches.
//     Correspondingly, the sequence for ensuring that modifications to instructions are available
//     for execution must include invalidation of the modified locations from the instruction cache,
//     even if the instructions are held in Normal Non-cacheable memory.
//     This includes cases where the instruction cache is disabled.
//
// To invalidate the AArch64 instruction cache after scatter-loading and before initialization of the stack and heap,
// it is necessary for the user to:
//
// * Implement instruction cache invalidation code in _platform_pre_stackheap_init.
// * Ensure all code on the path from the program entry up to and including _platform_pre_stackheap_init is located in a root region.

    .global _platform_pre_stackheap_init
    .type _platform_pre_stackheap_init, "function"
    .cfi_startproc
_platform_pre_stackheap_init:
    dsb ish     // ensure all previous stores have completed before invalidating
    ic  ialluis // I cache invalidate all inner shareable to PoU (which includes secondary cores)
    dsb ish     // ensure completion on inner shareable domain   (which includes secondary cores)
    isb

    // Scatter-loading is complete, so enable the caches here, so that the C-library's mutex initialization later will work
    mrs x1, SCTLR_EL1
    orr x1, x1, #SCTLR_ELx_C
    orr x1, x1, #SCTLR_ELx_I
    msr SCTLR_EL1, x1
    isb

    ret
    .cfi_endproc
