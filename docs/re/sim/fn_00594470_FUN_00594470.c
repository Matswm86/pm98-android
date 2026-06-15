// FUN_00594470  entry=00594470  size=245 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_00594470(int param_1,int param_2,int param_3,int param_4)

{
  int *piVar1;
  bool bVar2;
  char cVar3;
  int iVar4;
  int iVar5;
  int local_c;
  int local_8;
  
  if ((DAT_006d31c4 == '\0') && (*(int *)(param_1 + 0x1a38) == 0)) {
    if (param_3 == 0) {
      local_c = 0;
      local_8 = 0;
    }
    else {
      local_c = *(int *)(param_3 + 0x2b8);
      local_8 = *(int *)(param_3 + 0x2c0);
    }
    iVar5 = *(int *)(param_1 + 0x1a28) + 1;
    iVar4 = iVar5 * 0x10;
    FUN_005bbf10((int *)(param_1 + 0x1a24),iVar4);
    *(int *)(param_1 + 0x1a28) = iVar5;
    piVar1 = (int *)(*(int *)(param_1 + 0x1a24) + -0x10 + iVar4);
    *piVar1 = param_2;
    piVar1[1] = local_c;
    piVar1[2] = local_8;
    piVar1[3] = 0x168;
    if (param_4 == 1) {
      *(undefined4 *)(param_1 + 0x1a30) = 300;
    }
    cVar3 = FUN_005943d0();
    if ((cVar3 == '\0') && (cVar3 = FUN_005943b0(), cVar3 == '\0')) {
      bVar2 = false;
    }
    else {
      bVar2 = true;
    }
    if ((!bVar2) || ((param_2 != 1 && (param_4 != 1)))) {
      iVar4 = *(int *)(param_1 + 0x1a2c);
      if (*(int *)(param_1 + 0x1a2c) <= param_4) {
        iVar4 = param_4;
      }
      *(int *)(param_1 + 0x1a2c) = iVar4;
    }
  }
  return;
}


