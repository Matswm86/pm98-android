// FUN_005e5e20  entry=005e5e20  size=191 bytes

undefined1 * __thiscall FUN_005e5e20(undefined1 *param_1,int param_2)

{
  int iVar1;
  int iVar2;
  uint uVar3;
  int iVar4;
  bool bVar5;
  
  bVar5 = param_2 < 0;
  if (bVar5) {
    param_2 = -param_2;
    *param_1 = 0x2d;
  }
  uVar3 = (uint)bVar5;
  iVar4 = 1;
  iVar1 = param_2;
  while (999 < iVar1) {
    iVar4 = iVar4 * 1000;
    iVar1 = param_2 / iVar4;
  }
  iVar1 = sprintf(param_1 + uVar3,&DAT_00665d74,param_2 / iVar4);
  iVar1 = uVar3 + iVar1;
  param_2 = param_2 % iVar4;
  while (iVar4 = iVar4 / 1000, iVar4 != 0) {
    param_1[iVar1] = DAT_00665d64;
    iVar2 = sprintf(param_1 + iVar1 + 1,s__03lu_00665d6c,param_2 / iVar4);
    iVar1 = iVar1 + 1 + iVar2;
    param_2 = param_2 % iVar4;
  }
  return param_1;
}


