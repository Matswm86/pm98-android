// FUN_00404490  entry=00404490  size=122 bytes

void __thiscall FUN_00404490(void *this,int *param_1,int param_2,uint param_3)

{
  int iVar1;
  uint uVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  int local_10;
  
  uVar2 = FUN_004512f0(param_3,0x4f612c,0x100,-1);
  iVar3 = *param_1;
  iVar5 = param_1[1];
  iVar4 = param_2 + iVar3;
  iVar1 = iVar5 + 1;
  local_10 = iVar3;
  if (iVar4 <= iVar3) {
    local_10 = iVar4;
  }
  if (iVar3 <= iVar4) {
    iVar3 = iVar4;
  }
  iVar4 = iVar5;
  if (iVar1 <= iVar5) {
    iVar4 = iVar1;
  }
  if (iVar5 <= iVar1) {
    iVar5 = iVar1;
  }
  FUN_0044ed40(this,local_10,iVar4,iVar3,iVar5,uVar2);
  return;
}


