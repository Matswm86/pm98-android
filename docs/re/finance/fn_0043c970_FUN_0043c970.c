// FUN_0043c970  entry=0043c970  size=122 bytes

void FUN_0043c970(int *param_1,int param_2,undefined4 param_3)

{
  int iVar1;
  undefined4 uVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  int local_10;
  
  uVar2 = FUN_005db6b0(param_3,&DAT_006c29b4,0x100,0xffffffff);
  iVar3 = *param_1;
  iVar5 = param_1[1];
  param_2 = param_2 + iVar3;
  iVar1 = iVar5 + 1;
  local_10 = iVar3;
  if (param_2 <= iVar3) {
    local_10 = param_2;
  }
  if (iVar3 <= param_2) {
    iVar3 = param_2;
  }
  iVar4 = iVar5;
  if (iVar1 <= iVar5) {
    iVar4 = iVar1;
  }
  if (iVar5 <= iVar1) {
    iVar5 = iVar1;
  }
  FUN_005cb930(local_10,iVar4,iVar3,iVar5,uVar2);
  return;
}


