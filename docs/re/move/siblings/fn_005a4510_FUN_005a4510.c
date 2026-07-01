// FUN_005a4510  entry=005a4510  size=54 bytes

void __thiscall FUN_005a4510(int param_1,int *param_2,uint param_3,int *param_4)

{
  int iVar1;
  int iVar2;
  
  iVar2 = param_4[1];
  param_3 = *(uint *)(param_1 + 0x19a0) & 1 ^ param_3;
  if (param_3 != 0) {
    iVar2 = -iVar2;
  }
  iVar1 = *param_4;
  if (param_3 != 0) {
    iVar1 = -iVar1;
  }
  param_2[2] = param_4[2];
  *param_2 = iVar1;
  param_2[1] = iVar2;
  return;
}


