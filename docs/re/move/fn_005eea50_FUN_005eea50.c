// FUN_005eea50  entry=005eea50  size=40 bytes

undefined4 * __thiscall
FUN_005eea50(undefined4 *param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4)

{
  int iVar1;
  undefined4 *puVar2;
  
  puVar2 = param_1;
  for (iVar1 = 0xc; iVar1 != 0; iVar1 = iVar1 + -1) {
    *puVar2 = 0;
    puVar2 = puVar2 + 1;
  }
  *param_1 = param_2;
  param_1[8] = param_4;
  param_1[4] = param_3;
  return param_1;
}


