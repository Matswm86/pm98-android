// FUN_004d09b0  entry=004d09b0  size=238 bytes

bool __thiscall
FUN_004d09b0(int param_1,undefined4 param_2,int param_3,undefined4 param_4,int param_5,int param_6,
            undefined4 param_7,int param_8)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  undefined4 uVar5;
  undefined4 local_10;
  int local_c;
  int local_8;
  int local_4;
  
  iVar4 = param_8;
  local_10 = param_3;
  *(undefined4 *)(param_1 + 0x3f4) = param_7;
  iVar3 = param_8 + param_5;
  iVar1 = param_8 + param_6;
  local_c = param_6;
  *(int *)(param_1 + 0x3f8) = param_8;
  uVar5 = 0xffffffff;
  iVar2 = param_6;
  local_8 = iVar3;
  local_4 = iVar1;
  FUN_00436270(0xffffffff);
  iVar2 = FUN_005bc780(param_2,&local_10,&DAT_00666f70,0x800,0,iVar2,uVar5);
  if (iVar2 == 0) {
    return false;
  }
  param_3 = param_5;
  *(int *)(param_1 + 0x7f4) = iVar4;
  *(undefined4 *)(param_1 + 0x7f0) = param_7;
  uVar5 = 0xffffffff;
  iVar4 = param_5;
  param_5 = iVar3;
  param_6 = iVar1;
  FUN_00436270(0xffffffff);
  iVar3 = FUN_005bc780(param_2,&param_3,&DAT_00666f70,0x800,0,iVar4,uVar5);
  return iVar3 != 0;
}


