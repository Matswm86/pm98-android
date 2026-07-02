// FUN_005b1070  entry=005b1070  size=129 bytes

void __thiscall FUN_005b1070(int param_1,undefined4 param_2,int *param_3,undefined4 param_4)

{
  short sVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  int iVar4;
  int iVar5;
  
  iVar4 = *param_3 - *(int *)(param_1 + 4);
  iVar5 = param_3[1] - *(int *)(param_1 + 8);
  sVar1 = FUN_005ee080(iVar4,iVar5);
  uVar2 = FUN_005edfb0(iVar4,*(undefined4 *)(&DAT_006d31c8 + (sVar1 + 8 >> 4 & 0xfffU) * 4),iVar5,
                       *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar1 >> 4 & 0xfffU) * 4));
  uVar3 = FUN_005ee080(iVar4,iVar5);
  FUN_005b0fd0(param_2,uVar3,uVar2,param_4);
  return;
}


