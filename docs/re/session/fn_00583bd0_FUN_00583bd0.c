// FUN_00583bd0  entry=00583bd0  size=1541 bytes

void __thiscall FUN_00583bd0(undefined2 *param_1,int param_2,int *param_3,undefined4 *param_4)

{
  int *piVar1;
  undefined1 *puVar2;
  undefined1 uVar3;
  char cVar4;
  byte bVar5;
  undefined2 uVar6;
  short sVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  uint uVar11;
  void *pvVar12;
  undefined2 *puVar13;
  uint local_21c;
  uint local_218;
  int local_214;
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_006200ce;
  local_c = ExceptionList;
  local_214 = *param_3;
  uVar6 = *(undefined2 *)*param_4;
  ExceptionList = &local_c;
  *param_4 = (undefined2 *)*param_4 + 1;
  iVar10 = local_214 + param_2;
  *param_1 = uVar6;
  *(int *)(param_1 + 2) = iVar10;
  iVar10 = FUN_0058c810(iVar10);
  local_214 = local_214 + iVar10;
  iVar10 = local_214 + param_2;
  *(int *)(param_1 + 4) = iVar10;
  iVar10 = FUN_0058c810(iVar10);
  local_214 = local_214 + iVar10;
  sVar7 = *(short *)*param_4;
  *param_4 = (short *)*param_4 + 1;
  param_1[1] = sVar7;
  if (sVar7 == 0x26ae) {
    *(int *)(param_1 + 6) = local_214 + param_2;
    iVar10 = FUN_0058c810(local_214 + param_2);
    local_214 = local_214 + iVar10;
  }
  else {
    *(undefined4 *)(param_1 + 6) = 0;
  }
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0xe) = uVar3;
  uVar11 = 0;
  do {
    uVar3 = *(undefined1 *)*param_4;
    *param_4 = (undefined1 *)*param_4 + 1;
    *(undefined1 *)(uVar11 + 0x1d + (int)param_1) = uVar3;
    uVar11 = uVar11 + 1;
  } while (uVar11 < 6);
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x7c) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0xc) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0xd) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0xb) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0x17) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0x1b) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0x19) = uVar3;
  FUN_00446a90(param_4);
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0x23) = uVar3;
  FUN_005853a0(param_4);
  FUN_0058c110(param_4);
  FUN_00576f70(param_4);
  piVar1 = (int *)(param_1 + 0x46);
  cVar4 = *(char *)*param_4;
  *param_4 = (char *)*param_4 + 1;
  *(bool *)(param_1 + 0x4c) = cVar4 != '\0';
  bVar5 = *(byte *)*param_4;
  *param_4 = (byte *)*param_4 + 1;
  iVar8 = *(int *)(param_1 + 0x48);
  uVar11 = (uint)bVar5;
  iVar10 = iVar8 + -1;
  *(int *)(param_1 + 0x48) = iVar10;
  while (iVar9 = iVar10, iVar8 != 0) {
    iVar10 = iVar9 + -1;
    *(int *)(param_1 + 0x48) = iVar10;
    iVar8 = iVar9;
  }
  if (*piVar1 != 0) {
    FUN_005bbed0(*piVar1);
    *piVar1 = 0;
  }
  *(undefined4 *)(param_1 + 0x48) = 0;
  iVar10 = *(int *)(param_1 + 0x48);
  while ((int)uVar11 < iVar10) {
    iVar10 = *(int *)(param_1 + 0x48) + -1;
    *(int *)(param_1 + 0x48) = iVar10;
  }
  FUN_005bbf10(piVar1,uVar11 << 5);
  iVar10 = *(int *)(param_1 + 0x48);
  *(int *)(param_1 + 0x48) = iVar10;
  while (iVar10 < (int)uVar11) {
    iVar10 = *(int *)(param_1 + 0x48) * 0x20 + *piVar1;
    if (iVar10 != 0) {
      FUN_00576ca0();
      FUN_00576ca0();
      *(undefined4 *)(iVar10 + 0x1c) = 0;
    }
    iVar10 = *(int *)(param_1 + 0x48) + 1;
    *(int *)(param_1 + 0x48) = iVar10;
  }
  local_218 = 0;
  if (bVar5 != 0) {
    do {
      FUN_00577110(param_4);
      local_218 = local_218 + 1;
    } while (local_218 < uVar11);
  }
  FUN_005771c0(param_4);
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0x99) = uVar3;
  FUN_0058a7d0();
  cVar4 = *(char *)*param_4;
  *param_4 = (char *)*param_4 + 1;
  if (cVar4 != '\0') {
    pvVar12 = operator_new(0x1c);
    local_4 = 0;
    if (pvVar12 == (void *)0x0) {
      pvVar12 = (void *)0x0;
    }
    else {
      FUN_00576ca0();
    }
    local_4 = 0xffffffff;
    if (pvVar12 == (void *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    *(void **)(param_1 + 0x44) = pvVar12;
    FUN_00576f70(param_4);
  }
  uVar6 = *(undefined2 *)*param_4;
  *param_4 = (undefined2 *)*param_4 + 1;
  param_1[0x4d] = uVar6;
  puVar13 = param_1 + 0x62;
  do {
    uVar3 = *(undefined1 *)*param_4;
    *param_4 = (undefined1 *)*param_4 + 1;
    *(undefined1 *)(puVar13 + -7) = uVar3;
    uVar3 = *(undefined1 *)*param_4;
    *param_4 = (undefined1 *)*param_4 + 1;
    *(undefined1 *)puVar13 = uVar3;
    uVar3 = *(undefined1 *)*param_4;
    *param_4 = (undefined1 *)*param_4 + 1;
    *(undefined1 *)(puVar13 + 7) = uVar3;
    uVar3 = *(undefined1 *)*param_4;
    *param_4 = (undefined1 *)*param_4 + 1;
    *(undefined1 *)(puVar13 + 0xe) = uVar3;
    puVar13 = (undefined2 *)((int)puVar13 + 1);
  } while ((undefined1 *)((-0xc4 - (int)param_1) + (int)puVar13) < (undefined1 *)0xe);
  piVar1 = (int *)(param_1 + 0x78);
  bVar5 = *(byte *)*param_4;
  *param_4 = (byte *)*param_4 + 1;
  iVar8 = *(int *)(param_1 + 0x7a);
  local_21c = (uint)bVar5;
  iVar10 = iVar8 + -1;
  *(int *)(param_1 + 0x7a) = iVar10;
  while (iVar9 = iVar10, iVar8 != 0) {
    iVar10 = iVar9 + -1;
    *(int *)(param_1 + 0x7a) = iVar10;
    iVar8 = iVar9;
  }
  if (*piVar1 != 0) {
    FUN_005bbed0(*piVar1);
    *piVar1 = 0;
  }
  *(undefined4 *)(param_1 + 0x7a) = 0;
  uVar11 = *(uint *)(param_1 + 0x7a);
  while (local_21c < uVar11) {
    uVar11 = *(int *)(param_1 + 0x7a) - 1;
    *(uint *)(param_1 + 0x7a) = uVar11;
  }
  FUN_005bbf10(piVar1,local_21c * 4);
  uVar11 = *(uint *)(param_1 + 0x7a);
  *(uint *)(param_1 + 0x7a) = uVar11;
  while (uVar11 < local_21c) {
    puVar2 = (undefined1 *)(*piVar1 + *(int *)(param_1 + 0x7a) * 4);
    if (puVar2 != (undefined1 *)0x0) {
      *puVar2 = 0;
      puVar2[1] = 0;
      puVar2[2] = 0;
      puVar2[3] = 0;
    }
    uVar11 = *(int *)(param_1 + 0x7a) + 1;
    *(uint *)(param_1 + 0x7a) = uVar11;
  }
  uVar11 = 0;
  if (local_21c != 0) {
    do {
      uVar3 = *(undefined1 *)*param_4;
      puVar2 = (undefined1 *)(*piVar1 + uVar11 * 4);
      *param_4 = (undefined1 *)*param_4 + 1;
      *puVar2 = uVar3;
      uVar3 = *(undefined1 *)*param_4;
      *param_4 = (undefined1 *)*param_4 + 1;
      puVar2[1] = uVar3;
      uVar3 = *(undefined1 *)*param_4;
      *param_4 = (undefined1 *)*param_4 + 1;
      puVar2[2] = uVar3;
      uVar3 = *(undefined1 *)*param_4;
      *param_4 = (undefined1 *)*param_4 + 1;
      puVar2[3] = uVar3;
      uVar11 = uVar11 + 1;
    } while (uVar11 < local_21c);
  }
  if (DAT_0066c0c4 == 0x1e25) {
    FUN_004ece00(param_4);
  }
  uVar6 = *(undefined2 *)*param_4;
  *param_4 = (undefined2 *)*param_4 + 1;
  param_1[10] = uVar6;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0xa9) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x4e) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0x9d) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x4f) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0x9f) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0xa3) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x52) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x51) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0xa5) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0xa1) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x50) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x53) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0xa7) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x54) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x55) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0xab) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x56) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0xad) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0xb1) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x59) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x58) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0xb3) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0xaf) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x57) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x5a) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)((int)param_1 + 0xf9) = uVar3;
  uVar3 = *(undefined1 *)*param_4;
  *param_4 = (undefined1 *)*param_4 + 1;
  *(undefined1 *)(param_1 + 0x7d) = uVar3;
  FUN_004ece00(param_4);
  *param_3 = local_214;
  FUN_00586b40(param_1);
  if (*(char *)(param_1 + 0x4c) != '\0') {
    FUN_00587030(*param_1);
  }
  ExceptionList = local_c;
  return;
}


