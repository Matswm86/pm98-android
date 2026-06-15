// FUN_005e3c30  entry=005e3c30  size=112 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_005e3c30(int param_1,int *param_2,byte *param_3)

{
  byte *pbVar1;
  byte bVar2;
  int iVar3;
  int iVar4;
  uint local_4;
  
  iVar4 = 0;
  iVar3 = 0;
  bVar2 = *param_3;
  local_4 = (uint)*(byte *)(param_1 + 0x20);
  while (bVar2 != 0) {
    if ((bVar2 == 0xd) || (bVar2 == 10)) {
      local_4 = local_4 + *(byte *)(param_1 + 0x20);
      if (iVar4 <= iVar3) {
        iVar4 = iVar3;
      }
      iVar3 = 0;
    }
    else {
      iVar3 = iVar3 + (uint)*(byte *)(param_1 + 0x22 + (uint)bVar2);
    }
    pbVar1 = param_3 + 1;
    param_3 = param_3 + 1;
    bVar2 = *pbVar1;
  }
  if (iVar4 <= iVar3) {
    iVar4 = iVar3;
  }
  *param_2 = iVar4;
  param_2[1] = local_4;
  return;
}


