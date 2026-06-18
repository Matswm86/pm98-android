// FUN_005b8a60  entry=005b8a60  size=393 bytes

void __fastcall FUN_005b8a60(int *param_1)

{
  int iVar1;
  bool bVar2;
  uint uVar3;
  int iVar4;
  uint uVar5;
  int iVar6;
  int iVar7;
  int local_30;
  int local_2c;
  int local_10;
  
  iVar1 = param_1[0x4e];
  iVar6 = 0x27100000;
  local_2c = 0x27100000;
  local_30 = 0;
  if ((*(int *)(iVar1 + 0x1650) != 0) && (*(int *)(iVar1 + 0x1664) == param_1[2])) {
    param_1[0x81] = *(int *)(iVar1 + 0x1650);
    iVar6 = 0;
  }
  local_10 = param_1[1];
  iVar7 = *param_1;
  while (local_10 != 0) {
    local_10 = local_10 + -1;
    if (*(int *)(iVar7 + 700) != 0) {
      if (iVar7 == 0) {
        iVar4 = 0xc80000;
      }
      else {
        uVar3 = *(int *)(iVar7 + 4) - *(int *)(iVar7 + 0x3a4);
        uVar5 = (int)uVar3 >> 0x1f;
        iVar4 = (uVar3 ^ uVar5) - uVar5;
      }
      if (local_30 < iVar4) {
        param_1[0x7f] = iVar7;
        local_30 = iVar4;
      }
      if (iVar4 < local_2c) {
        param_1[0x80] = iVar7;
        local_2c = iVar4;
      }
      uVar3 = *(int *)(iVar7 + 4) - *(int *)(iVar1 + 0x1614);
      uVar5 = (int)uVar3 >> 0x1f;
      if ((((int)((uVar3 ^ uVar5) - uVar5) < iVar6) &&
          (uVar3 = *(int *)(iVar7 + 8) - *(int *)(iVar1 + 0x1618), uVar5 = (int)uVar3 >> 0x1f,
          (int)((uVar3 ^ uVar5) - uVar5) < iVar6)) &&
         (uVar3 = *(int *)(iVar7 + 0xc) - *(int *)(iVar1 + 0x161c), uVar5 = (int)uVar3 >> 0x1f,
         (int)((uVar3 ^ uVar5) - uVar5) < iVar6)) {
        bVar2 = true;
      }
      else {
        bVar2 = false;
      }
      if ((bVar2) && (iVar4 = ftol(), iVar4 < iVar6)) {
        param_1[0x81] = iVar7;
        iVar6 = iVar4;
      }
    }
    iVar7 = iVar7 + 0x3bc;
  }
  return;
}


