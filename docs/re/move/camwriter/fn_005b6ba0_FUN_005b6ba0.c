// FUN_005b6ba0  entry=005b6ba0  size=590 bytes

void __fastcall FUN_005b6ba0(int *param_1)

{
  int iVar1;
  int *piVar2;
  int iVar3;
  int iVar4;
  uint local_8;
  int local_4;
  
  local_8 = 0;
  local_4 = 0;
  FUN_005b6ee0();
  iVar1 = param_1[1];
  param_1[0x5a] = 0;
  while (0 < iVar1) {
    param_1[1] = iVar1 + -1;
    if (*param_1 + (iVar1 + -1) * 0x3bc != 0) {
      FUN_005b9420(1);
    }
    iVar1 = param_1[1];
  }
  FUN_005bbf10(param_1,0);
  iVar1 = param_1[1];
  param_1[1] = iVar1;
  while (iVar1 < 0) {
    if (*param_1 + param_1[1] * 0x3bc != 0) {
      FUN_005b6df0();
    }
    iVar1 = param_1[1] + 1;
    param_1[1] = iVar1;
  }
  iVar1 = param_1[0x27];
  iVar3 = 0;
  iVar4 = 0;
  param_1[0xbf] = *(int *)(iVar1 + 4);
  param_1[0xc0] = *(int *)(iVar1 + 8);
  param_1[0xc1] = *(int *)(iVar1 + 0x10);
  param_1[0xc2] = *(int *)(iVar1 + 0x14);
  param_1[0xc3] = *(int *)(iVar1 + 0x18);
  param_1[0xc4] = *(int *)(iVar1 + 0x1c);
  param_1[0xc5] = *(int *)(iVar1 + 0x20);
  param_1[0xc6] = *(int *)(iVar1 + 0x24);
  param_1[199] = *(int *)(iVar1 + 0x28);
  do {
    if (*(int *)(iVar4 + 0x70 + param_1[0x27]) == 0) {
      *(undefined4 *)(iVar4 + 0x70 + param_1[0x27]) = 0;
    }
    else {
      FUN_005bbf10(param_1,(param_1[1] + 1) * 0x3bc);
      if (*param_1 + param_1[1] * 0x3bc != 0) {
        FUN_005a2830(param_1[2],iVar3,param_1[0x4e],iVar4 + 0x2c + param_1[0x27]);
      }
      param_1[1] = param_1[1] + 1;
    }
    iVar4 = iVar4 + 0xac;
    iVar3 = iVar3 + 1;
  } while (iVar4 < 0x764);
  iVar3 = 0;
  iVar1 = 0;
  piVar2 = param_1 + 0x4f;
  do {
    if (*(int *)(iVar3 + 0x70 + param_1[0x27]) == 0) {
      *piVar2 = 0;
    }
    else {
      *piVar2 = *param_1 + iVar1;
      iVar1 = iVar1 + 0x3bc;
    }
    iVar3 = iVar3 + 0xac;
    piVar2 = piVar2 + 1;
  } while (iVar3 < 0x764);
  piVar2 = param_1 + 0x5b;
  for (iVar1 = 0x24; iVar1 != 0; iVar1 = iVar1 + -1) {
    *piVar2 = 0;
    piVar2 = piVar2 + 1;
  }
  iVar1 = param_1[1];
  iVar3 = *param_1;
  while (iVar1 != 0) {
    iVar1 = iVar1 + -1;
    iVar4 = *(int *)(iVar3 + 0x2c8);
    if (param_1[iVar4 * 2 + 0x5b] == 0) {
      param_1[iVar4 * 2 + 0x5b] = iVar3;
    }
    else if (param_1[iVar4 * 2 + 0x5c] == 0) {
      param_1[iVar4 * 2 + 0x5c] = iVar3;
    }
    if (((*(int *)(iVar3 + 0x2c8) == 5) || (*(int *)(iVar3 + 0x2c8) == 6)) &&
       ((int)local_8 < *(int *)(iVar3 + 0x39c))) {
      local_8 = (uint)*(byte *)(iVar3 + 0x39c);
      local_4 = iVar3;
    }
    iVar3 = iVar3 + 0x3bc;
  }
  if (local_4 != 0) {
    *(undefined1 *)(local_4 + 0x2d6) = 1;
  }
  param_1[0xb8] = -1;
  *(undefined1 *)((int)param_1 + 0x2ed) = 0;
  FUN_005bbf10(param_1 + 0x82,0);
  param_1[0x83] = 0;
  return;
}


