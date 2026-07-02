// FUN_00512bc0  entry=00512bc0  size=372 bytes

void FUN_00512bc0(int param_1,int *param_2,int param_3,int param_4,int param_5,undefined4 param_6,
                 undefined4 param_7,undefined4 param_8)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  undefined4 local_28;
  undefined4 local_24;
  int local_20 [8];
  
  local_20[1] = 0x70000000;
  local_20[0] = 0x70000000;
  iVar4 = *(int *)(param_5 + 0x14) + param_3;
  local_20[3] = 0x90000000;
  local_20[2] = 0x90000000;
  local_28 = 0xb;
  iVar2 = param_2[1] + 2;
  local_24 = 0;
  local_20[4] = param_3;
  if (iVar4 <= param_3) {
    local_20[4] = iVar4;
  }
  if (param_3 <= iVar4) {
    param_3 = iVar4;
  }
  iVar4 = *(int *)(param_5 + 0x18) + iVar2;
  iVar3 = iVar2;
  if (iVar4 <= iVar2) {
    iVar3 = iVar4;
  }
  if (iVar4 < iVar2) {
    iVar4 = iVar2;
  }
  FUN_004f79b0(param_1,local_20[4],iVar3,param_3,iVar4,&local_28,param_5,param_7,param_6,param_8,
               local_20,(uint)*(byte *)(param_4 + 1) * 10 + -1);
  uVar1 = *(uint *)(param_1 + 0x144);
  *(uint *)(param_1 + 0x144) = uVar1 | 0x20;
  iVar3 = *param_2 + 4;
  iVar2 = (param_2[2] - *param_2) + -8 + iVar3;
  iVar4 = param_2[1] + 1;
  local_20[0] = iVar3;
  if (iVar2 <= iVar3) {
    local_20[0] = iVar2;
  }
  if (iVar2 < iVar3) {
    iVar2 = iVar3;
  }
  iVar5 = (param_2[3] - param_2[1]) + -2 + iVar4;
  iVar3 = iVar4;
  if (iVar5 <= iVar4) {
    iVar3 = iVar5;
  }
  if (iVar4 <= iVar5) {
    iVar4 = iVar5;
  }
  if ((uVar1 & 8) == 0) {
    FUN_005d9d80(*(undefined4 *)(param_4 + 4),local_20[0],iVar3,iVar2,iVar4,0x100);
  }
  else {
    FUN_005da180(*(undefined4 *)(param_4 + 4),local_20[0],iVar3,iVar2,iVar4,0x100,1);
  }
  *(uint *)(param_1 + 0x144) = *(uint *)(param_1 + 0x144) & 0xffffffdf;
  return;
}


