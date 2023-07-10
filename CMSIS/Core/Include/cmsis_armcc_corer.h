/**************************************************************************//**
 * @file     cmsis_armcc_corer.h
 * @brief    CMSIS compiler ARMCC (Arm Compiler 5) header file
 * @version  V5.0.0
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

#ifndef __CMSIS_ARMCC_CORER_H
#define __CMSIS_ARMCC_CORER_H

// Include the generic settings:
#include "cmsis_armcc.h"


/** \brief  Get Stack Pointer
    \return Stack Pointer
 */
__STATIC_INLINE __ASM uint32_t __get_SP(void)
{
  MOV  r0, sp
  BX   lr
}

/** \brief  Set Stack Pointer
    \param [in]    stack  Stack Pointer value to set
 */
__STATIC_INLINE __ASM void __set_SP(uint32_t stack)
{
  MOV  sp, r0
  BX   lr
}


#endif /* __CMSIS_ARMCC_CORER_H */
