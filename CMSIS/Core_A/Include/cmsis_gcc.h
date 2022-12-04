/**************************************************************************//**
 * @file     cmsis_gcc.h
 * @brief    CMSIS compiler GCC header file
 * @version  V5.5.0
 * @date     04. December 2022
 ******************************************************************************/
/*
 * Copyright (c) 2009-2023 Arm Limited. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the License); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef __CMSIS_GCC_H
#define __CMSIS_GCC_H

// Include the generic settigs:
#include "../../Core/cmsis_generic_gcc.h"

/* ignore some GCC warnings */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wsign-conversion"
#pragma GCC diagnostic ignored "-Wconversion"
#pragma GCC diagnostic ignored "-Wunused-parameter"


/** \defgroup CMSIS_Core_intrinsics CMSIS Core Intrinsics
  Access to dedicated SIMD instructions
  @{
*/
#if __CORTEX_A == 5 ||__CORTEX_A == 7 || __CORTEX_A == 9
  /** \brief  Get CPSR Register
      \return               CPSR Register value
   */
  __STATIC_FORCEINLINE uint32_t __get_CPSR(void)
  {
    uint32_t result;
    __ASM volatile("MRS %0, cpsr" : "=r" (result) );
    return(result);
  }
  
  /** \brief  Set CPSR Register
      \param [in]    cpsr  CPSR value to set
   */
  __STATIC_FORCEINLINE void __set_CPSR(uint32_t cpsr)
  {
    __ASM volatile ("MSR cpsr, %0" : : "r" (cpsr) : "cc", "memory");
  }
  
  /** \brief  Get Mode
      \return                Processor Mode
   */
  __STATIC_FORCEINLINE uint32_t __get_mode(void)
  {
    return (__get_CPSR() & 0x1FU);
  }
  
  /** \brief  Set Mode
      \param [in]    mode  Mode value to set
   */
  __STATIC_FORCEINLINE void __set_mode(uint32_t mode)
  {
    __ASM volatile("MSR  cpsr_c, %0" : : "r" (mode) : "memory");
  }
#elif __CORTEX_A == 35 || __CORTEX_A == 53 || __CORTEX_A == 57
  /** \brief  Get MPIDR EL1
      \return Multiprocessor Affinity Register value
   */
  __STATIC_FORCEINLINE uint64_t __get_MPIDR_EL1(void)
  {
    uint64_t result;
    __ASM volatile("MRS %0, MPIDR_EL1" : "=r" (result) : : "memory");
    return result;
  }
  
  /** \brief  Get MAIR EL3
      \return               MAIR value
   */
  __STATIC_FORCEINLINE uint64_t __get_MAIR_EL3(void)
  {
    uint64_t result;
    __ASM volatile("MRS  %0, mair_el3" : "=r" (result) : : "memory");
    return result;
  }
  
  /** \brief  Set MAIR EL3
      \param [in]    mair  MAIR value to set
   */
  __STATIC_FORCEINLINE void __set_MAIR_EL3(uint64_t mair)
  {
    __ASM volatile("MSR  mair_el3, %0" : : "r" (mair) : "memory");
  }
  
  /** \brief  Get TCR EL3
      \return               TCR value
   */
  __STATIC_FORCEINLINE uint64_t __get_TCR_EL3(void)
  {
    uint64_t result;
    __ASM volatile("MRS  %0, tcr_el3" : "=r" (result) : : "memory");
    return result;
  }
  
  /** \brief  Set TCR EL3
      \param [in]    tcr  TCR value to set
   */
  __STATIC_FORCEINLINE void __set_TCR_EL3(uint64_t tcr)
  {
    __ASM volatile("MSR  tcr_el3, %0" : : "r" (tcr) : "memory");
  }
  
  /** \brief  Get TTBR0 EL3
      \return               Translation Table Base Register 0 value
   */
  __STATIC_FORCEINLINE uint64_t __get_TTBR0_EL3(void)
  {
    uint64_t result;
    __ASM volatile("MRS  %0, ttbr0_el3" : "=r" (result) : : "memory");
    return result;
  }
  
  /** \brief  Set TTBR0 EL3
      \param [in]    ttbr0  Translation Table Base Register 0 value to set
   */
  __STATIC_FORCEINLINE void __set_TTBR0_EL3(uint64_t ttbr0)
  {
    __ASM volatile("MSR  ttbr0_el3, %0" : : "r" (ttbr0) : "memory");
  }
  
  /** \brief  Get SCTLR EL3
      \return STRLR EL3 value
   */
  __STATIC_FORCEINLINE uint64_t __get_SCTLR_EL3(void)
  {
    uint64_t result;
    __ASM volatile("MRS  %0, sctlr_el3" : "=r" (result) : : "memory");
    return result;
  }
  
  /** \brief  Set SCTLR EL3
      \param [in]    vbar  SCTLR value to set
   */
  __STATIC_FORCEINLINE void __set_SCTLR_EL3(uint64_t sctlr)
  {
    __ASM volatile("MSR  sctlr_el3, %0" : : "r" (sctlr) : "memory");
  }
  
  /** \brief  Set VBAR EL3
      \param [in]    vbar  VBAR value to set
   */
  __STATIC_FORCEINLINE void __set_VBAR_EL3(uint64_t vbar)
  {
    __ASM volatile("MSR  vbar_el3, %0" : : "r" (vbar) : "memory");
  }
  
  /** \brief  Set VBAR EL2
      \param [in]    vbar  VBAR value to set
   */
  __STATIC_FORCEINLINE void __set_VBAR_EL2(uint64_t vbar)
  {
    __ASM volatile("MSR  vbar_el2, %0" : : "r" (vbar) : "memory");
  }
  
  /** \brief  Set VBAR EL1
      \param [in]    vbar  VBAR value to set
   */
  __STATIC_FORCEINLINE void __set_VBAR_EL1(uint64_t vbar)
  {
    __ASM volatile("MSR  vbar_el1, %0" : : "r" (vbar) : "memory");
  }
#else /* #elif __CORTEX_A == 35 || __CORTEX_A == 53 || __CORTEX_A == 57 */
  #warning "Unknown or unsupported core"
#endif

/** \brief  Get Stack Pointer
    \return Stack Pointer value
 */
__STATIC_FORCEINLINE uint32_t __get_SP(void)
{
  uint32_t result;
  __ASM volatile("MOV  %0, sp" : "=r" (result) : : "memory");
  return result;
}

/** \brief  Set Stack Pointer
    \param [in]    stack  Stack Pointer value to set
 */
__STATIC_FORCEINLINE void __set_SP(uint32_t stack)
{
  __ASM volatile("MOV  sp, %0" : : "r" (stack) : "memory");
}

#if __CORTEX_A == 5 ||__CORTEX_A == 7 || __CORTEX_A == 9
  /** \brief  Get USR/SYS Stack Pointer
      \return USR/SYS Stack Pointer value
   */
  __STATIC_FORCEINLINE uint32_t __get_SP_usr(void)
  {
    uint32_t cpsr = __get_CPSR();
    uint32_t result;
    __ASM volatile(
      "CPS     #0x1F  \n"
      "MOV     %0, sp   " : "=r"(result) : : "memory"
     );
    __set_CPSR(cpsr);
    __ISB();
    return result;
  }
  
  /** \brief  Set USR/SYS Stack Pointer
      \param [in]    topOfProcStack  USR/SYS Stack Pointer value to set
   */
  __STATIC_FORCEINLINE void __set_SP_usr(uint32_t topOfProcStack)
  {
    uint32_t cpsr = __get_CPSR();
    __ASM volatile(
      "CPS     #0x1F  \n"
      "MOV     sp, %0   " : : "r" (topOfProcStack) : "memory"
     );
    __set_CPSR(cpsr);
    __ISB();
  }
#endif

/** \brief  Get FPEXC
    \return               Floating Point Exception Control register value
 */
__STATIC_FORCEINLINE uint32_t __get_FPEXC(void)
{
#if (__FPU_PRESENT == 1)
  uint32_t result;
  __ASM volatile("VMRS %0, fpexc" : "=r" (result) : : "memory");
  return(result);
#else
  return(0);
#endif
}

/** \brief  Set FPEXC
    \param [in]    fpexc  Floating Point Exception Control value to set
 */
__STATIC_FORCEINLINE void __set_FPEXC(uint32_t fpexc)
{
#if (__FPU_PRESENT == 1)
  __ASM volatile ("VMSR fpexc, %0" : : "r" (fpexc) : "memory");
#endif
}

/*
 * Include common core functions to access Coprocessor 15 registers
 */

#define __get_CP(cp, op1, Rt, CRn, CRm, op2) __ASM volatile("MRC p" # cp ", " # op1 ", %0, c" # CRn ", c" # CRm ", " # op2 : "=r" (Rt) : : "memory" )
#define __set_CP(cp, op1, Rt, CRn, CRm, op2) __ASM volatile("MCR p" # cp ", " # op1 ", %0, c" # CRn ", c" # CRm ", " # op2 : : "r" (Rt) : "memory" )
#define __get_CP64(cp, op1, Rt, CRm)         __ASM volatile("MRRC p" # cp ", " # op1 ", %Q0, %R0, c" # CRm  : "=r" (Rt) : : "memory" )
#define __set_CP64(cp, op1, Rt, CRm)         __ASM volatile("MCRR p" # cp ", " # op1 ", %Q0, %R0, c" # CRm  : : "r" (Rt) : "memory" )

#include "cmsis_cp15.h"

/** \brief  Enable Floating Point Unit

  Critical section, called from undef handler, so systick is disabled
 */
#if __CORTEX_A == 5 ||__CORTEX_A == 7 || __CORTEX_A == 9
  __STATIC_INLINE void __FPU_Enable(void)
  {
    __ASM volatile(
      //Permit access to VFP/NEON, registers by modifying CPACR
      "        MRC     p15,0,R1,c1,c0,2  \n"
      "        ORR     R1,R1,#0x00F00000 \n"
      "        MCR     p15,0,R1,c1,c0,2  \n"
  
      //Ensure that subsequent instructions occur in the context of VFP/NEON access permitted
      "        ISB                       \n"
  
      //Enable VFP/NEON
      "        VMRS    R1,FPEXC          \n"
      "        ORR     R1,R1,#0x40000000 \n"
      "        VMSR    FPEXC,R1          \n"
  
      //Initialise VFP/NEON registers to 0
      "        MOV     R2,#0             \n"
  
      //Initialise D16 registers to 0
      "        VMOV    D0, R2,R2         \n"
      "        VMOV    D1, R2,R2         \n"
      "        VMOV    D2, R2,R2         \n"
      "        VMOV    D3, R2,R2         \n"
      "        VMOV    D4, R2,R2         \n"
      "        VMOV    D5, R2,R2         \n"
      "        VMOV    D6, R2,R2         \n"
      "        VMOV    D7, R2,R2         \n"
      "        VMOV    D8, R2,R2         \n"
      "        VMOV    D9, R2,R2         \n"
      "        VMOV    D10,R2,R2         \n"
      "        VMOV    D11,R2,R2         \n"
      "        VMOV    D12,R2,R2         \n"
      "        VMOV    D13,R2,R2         \n"
      "        VMOV    D14,R2,R2         \n"
      "        VMOV    D15,R2,R2         \n"
  
  #if (defined(__ARM_NEON) && (__ARM_NEON == 1))
      //Initialise D32 registers to 0
      "        VMOV    D16,R2,R2         \n"
      "        VMOV    D17,R2,R2         \n"
      "        VMOV    D18,R2,R2         \n"
      "        VMOV    D19,R2,R2         \n"
      "        VMOV    D20,R2,R2         \n"
      "        VMOV    D21,R2,R2         \n"
      "        VMOV    D22,R2,R2         \n"
      "        VMOV    D23,R2,R2         \n"
      "        VMOV    D24,R2,R2         \n"
      "        VMOV    D25,R2,R2         \n"
      "        VMOV    D26,R2,R2         \n"
      "        VMOV    D27,R2,R2         \n"
      "        VMOV    D28,R2,R2         \n"
      "        VMOV    D29,R2,R2         \n"
      "        VMOV    D30,R2,R2         \n"
      "        VMOV    D31,R2,R2         \n"
  #endif
  
      //Initialise FPSCR to a known state
      "        VMRS    R1,FPSCR          \n"
      "        LDR     R2,=0x00086060    \n" //Mask off all bits that do not have to be preserved. Non-preserved bits can/should be zero.
      "        AND     R1,R1,R2          \n"
      "        VMSR    FPSCR,R1            "
      : : : "cc", "r1", "r2"
    );
  }
#elif __CORTEX_A == 35 || __CORTEX_A == 53 || __CORTEX_A == 57
  __STATIC_INLINE void __FPU_Enable(void)
  {
    __ASM volatile(
      // In AArch64, you do not need to enable access to the NEON and FP registers.
      // However, access to  the NEON and FP registers can still be trapped.
  
      // Disable trapping of   accessing in EL3 and EL2.
      "        MSR    CPTR_EL3, XZR    \n"
      "        MSR    CPTR_EL2, XZR    \n"
  
      // Disable access trapping in EL1 and EL0.
      "        MOV    X1, #(0x3 << 20) \n"
  
      // FPEN disables trapping to EL1.
      "        MSR    CPACR_EL1, X1    \n"
  
      //Ensure that subsequent instructions occur in the context of VFP/NEON access permitted
      "        ISB                       "
  
      : : : "cc", "x1"
    );
  }
#endif /* #elif __CORTEX_A == 35 || __CORTEX_A == 53 || __CORTEX_A == 57 */
/*@} end of group CMSIS_Core_intrinsics */

#pragma GCC diagnostic pop

#endif /* __CMSIS_GCC_H */
