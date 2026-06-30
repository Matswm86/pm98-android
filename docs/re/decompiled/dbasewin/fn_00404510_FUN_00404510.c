// FUN_00404510  entry=00404510  size=122 bytes

void __thiscall FUN_00404510(void *this,int *param_1,int param_2,uint param_3)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  int local_10;
  
  uVar1 = FUN_004512f0(param_3,0x4f612c,0x100,-1);
  iVar2 = *param_1;
  iVar4 = param_1[1];
  iVar5 = param_2 + iVar4;
  iVar3 = iVar2 + 1;
  local_10 = iVar2;
  if (iVar3 <= iVar2) {
    local_10 = iVar3;
  }
  if (iVar2 <= iVar3) {
    iVar2 = iVar3;
  }
  iVar3 = iVar4;
  if (iVar5 <= iVar4) {
    iVar3 = iVar5;
  }
  if (iVar4 <= iVar5) {
    iVar4 = iVar5;
  }
  FUN_0044ed40(this,local_10,iVar3,iVar2,iVar4,uVar1);
  return;
}


