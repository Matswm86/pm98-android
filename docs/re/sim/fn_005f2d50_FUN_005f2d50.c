// FUN_005f2d50  entry=005f2d50  size=413 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_005f2d50(int *param_1,undefined4 param_2)

{
  int *piVar1;
  int *piVar2;
  int iVar3;
  int *piVar4;
  undefined1 *puVar5;
  undefined1 local_1a0 [264];
  int *local_98;
  int *local_94;
  int local_90;
  int local_8c [32];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_006223eb;
  local_c = ExceptionList;
  local_1a0[0] = 0;
  local_98 = (int *)0x0;
  local_94 = (int *)0x0;
  local_90 = 0;
  ExceptionList = &local_c;
  FUN_005ec020(param_2);
  local_4 = 0;
  piVar4 = local_94 + 1;
  if (-*local_94 < 0x800000) {
    piVar2 = (int *)(local_90 + (int)local_98);
    piVar4 = piVar2;
    if (local_94 <= piVar2) {
      piVar4 = local_94;
    }
    piVar1 = local_98;
    if ((local_98 <= piVar4) && (piVar1 = local_94, piVar2 < local_94)) {
      piVar1 = piVar2;
    }
    local_94 = piVar1;
    if (param_1[1] == 0) {
      FUN_005bbf10(param_1,0x13c);
      iVar3 = param_1[1];
      param_1[1] = iVar3;
      while (iVar3 < 1) {
        if (*param_1 + param_1[1] * 0x13c != 0) {
          FUN_005f02d0(&DAT_00666f70);
        }
        iVar3 = param_1[1] + 1;
        param_1[1] = iVar3;
      }
    }
    FUN_005f03a0(local_1a0);
  }
  else {
    local_94 = piVar4;
    if (piVar4 < (int *)((int)local_98 + local_90)) {
      do {
        local_8c[0]._0_1_ = 0;
        puVar5 = local_1a0;
        piVar4 = local_94;
        piVar2 = local_8c;
        for (iVar3 = 0x20; iVar3 != 0; iVar3 = iVar3 + -1) {
          *piVar2 = *piVar4;
          piVar4 = piVar4 + 1;
          piVar2 = piVar2 + 1;
        }
        local_94 = local_94 + 0x20;
        FUN_005f2ef0(local_8c);
        FUN_005f03a0(puVar5);
      } while (local_94 < (int *)((int)local_98 + local_90));
    }
  }
  local_4 = 0xffffffff;
  FUN_005ec0e0();
  ExceptionList = local_c;
  return;
}


