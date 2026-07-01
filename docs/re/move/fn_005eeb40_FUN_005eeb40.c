// FUN_005eeb40  entry=005eeb40  size=87 bytes

undefined4 * __thiscall FUN_005eeb40(undefined4 *param_1,short param_2)

{
  undefined4 uVar1;
  int iVar2;
  undefined4 *puVar3;
  
  puVar3 = param_1;
  for (iVar2 = 0xc; iVar2 != 0; iVar2 = iVar2 + -1) {
    *puVar3 = 0;
    puVar3 = puVar3 + 1;
  }
  uVar1 = *(undefined4 *)(&DAT_006d31c8 + (param_2 + 8 >> 4 & 0xfffU) * 4);
  param_1[8] = uVar1;
  param_1[4] = uVar1;
  iVar2 = *(int *)(&DAT_006d31c8 + (0x3ff8 - param_2 >> 4 & 0xfffU) * 4);
  *param_1 = 0x10000;
  param_1[5] = iVar2;
  param_1[7] = -iVar2;
  return param_1;
}


