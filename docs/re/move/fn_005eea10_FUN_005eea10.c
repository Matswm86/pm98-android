// FUN_005eea10  entry=005eea10  size=54 bytes

undefined4 * __thiscall FUN_005eea10(undefined4 *param_1,undefined4 *param_2)

{
  int iVar1;
  undefined4 *puVar2;
  
  puVar2 = param_1;
  for (iVar1 = 0xc; iVar1 != 0; iVar1 = iVar1 + -1) {
    *puVar2 = 0;
    puVar2 = puVar2 + 1;
  }
  param_1[8] = 0x10000;
  param_1[4] = 0x10000;
  *param_1 = 0x10000;
  param_1[9] = *param_2;
  param_1[10] = param_2[1];
  param_1[0xb] = param_2[2];
  return param_1;
}


