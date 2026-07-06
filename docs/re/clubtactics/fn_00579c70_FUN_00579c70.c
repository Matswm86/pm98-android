// FUN_00579c70  entry=00579c70  size=1289 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 __thiscall FUN_00579c70(int *param_1,int param_2,uint *param_3)

{
  undefined2 *puVar1;
  byte bVar2;
  undefined1 uVar3;
  undefined2 uVar4;
  ushort uVar5;
  uint uVar6;
  float10 fVar7;
  void *pvVar8;
  void *pvVar9;
  int iVar10;
  uint uVar11;
  uint uVar12;
  ushort *puVar13;
  uint *puVar14;
  char cVar15;
  uint local_238;
  void *local_234;
  uint local_230;
  uint local_22c;
  void *local_228;
  uint local_224;
  undefined4 uStack_220;
  void *local_21c;
  undefined4 local_218;
  uint local_214;
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0061feee;
  local_c = ExceptionList;
  uVar11 = *param_3;
  puVar13 = (ushort *)(uVar11 + 0x24);
  ExceptionList = &local_c;
  *param_3 = (uint)puVar13;
  local_214 = (uint)*puVar13;
  *param_3 = uVar11 + 0x26;
  pvVar9 = operator_new(local_214);
  local_21c = pvVar9;
  if (pvVar9 == (void *)0x0) {
    local_210 = 0xffff0002;
    lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  param_1[3] = (int)pvVar9;
  if (pvVar9 == (void *)0x0) {
    ExceptionList = local_c;
    return 0;
  }
  puVar13 = (ushort *)*param_3;
  local_238 = 0;
  local_22c = (uint)*puVar13;
  *param_3 = (uint)((int)puVar13 + 3);
  local_230 = (uint)*(byte *)((int)puVar13 + 3);
  uVar11 = local_230;
  *param_3 = (uint)(puVar13 + 2);
  param_1[1] = (int)pvVar9;
  iVar10 = FUN_0058c810(pvVar9);
  local_238 = local_238 + iVar10;
  param_1[2] = (int)pvVar9 + local_238;
  iVar10 = FUN_0058c810((int)pvVar9 + local_238);
  local_238 = local_238 + iVar10;
  if (param_2 == 9) goto LAB_0057a137;
  bVar2 = *(byte *)*param_3;
  local_234 = (void *)CONCAT31(local_234._1_3_,bVar2);
  *param_3 = (uint)((byte *)*param_3 + 1);
  param_1[5] = (uint)bVar2;
  *param_1 = local_238 + (int)pvVar9;
  iVar10 = FUN_0058c810(local_238 + (int)pvVar9);
  local_238 = local_238 + iVar10;
  iVar10 = *(int *)*param_3;
  *param_3 = (uint)((int *)*param_3 + 1);
  param_1[6] = iVar10;
  if (local_22c < 0x1fe) {
    param_1[7] = 0;
  }
  else {
    iVar10 = *(int *)*param_3;
    *param_3 = (uint)((int *)*param_3 + 1);
    param_1[7] = iVar10;
  }
  uVar4 = *(undefined2 *)*param_3;
  *param_3 = (uint)((undefined2 *)*param_3 + 1);
  *(undefined2 *)(param_1 + 0xd) = uVar4;
  uVar5 = *(ushort *)*param_3;
  local_234 = (void *)CONCAT22((short)((uint)iVar10 >> 0x10),uVar5);
  *param_3 = (uint)((ushort *)*param_3 + 1);
  *(ushort *)((int)param_1 + 0x36) = uVar5;
  if ((uint)param_1[6] < 10) {
    param_1[6] = 6000;
  }
  uVar6 = param_1[7];
  if (uVar6 != 0) {
    uVar12 = (uint)param_1[7] / 4000;
    param_1[7] = uVar12;
    if ((uVar12 == 0) || (1999 < uVar6 % 4000)) {
      param_1[7] = uVar12 + 1;
    }
    param_1[7] = param_1[7] * 4000;
  }
  if (*(ushort *)(param_1 + 0xd) < 0x1e) {
    *(undefined2 *)(param_1 + 0xd) = 0x3c;
  }
  if (uVar5 < 0x34) {
    *(undefined2 *)((int)param_1 + 0x36) = 0x69;
  }
  uVar4 = *(undefined2 *)*param_3;
  *param_3 = (uint)((undefined2 *)*param_3 + 1);
  *(undefined2 *)(param_1 + 0xe) = uVar4;
  if (uVar11 == 0) {
    if (0x207 < local_22c) {
      *param_3 = *param_3 + 2;
    }
    iVar10 = *(int *)*param_3;
    *param_3 = (uint)((int *)*param_3 + 1);
    param_1[8] = iVar10;
    puVar14 = (uint *)((int)*param_3 + *(ushort *)*param_3 + 6);
    *param_3 = (uint)puVar14;
    local_224 = *puVar14;
    *param_3 = (uint)(puVar14 + 1);
    if (local_224 < 10) {
      local_224 = 0x50;
    }
    uStack_220 = 0;
    fVar7 = (float10)_DAT_00638d50;
    param_1[0x7a] = (int)(float)((float10)local_224 * fVar7);
    param_1[0x7b] = (int)(float)((float10)local_224 * fVar7);
    puVar13 = (ushort *)((int)*param_3 + *(ushort *)*param_3 + 2);
    *param_3 = (uint)puVar13;
    puVar1 = (undefined2 *)(*puVar13 + 2 + (int)puVar13);
    *param_3 = (uint)puVar1;
    uVar4 = *puVar1;
    *param_3 = (uint)(puVar1 + 1);
    *(undefined2 *)(param_1 + 0x9e) = uVar4;
    uVar4 = *(undefined2 *)*param_3;
    *param_3 = (uint)((undefined2 *)*param_3 + 1);
    *(undefined2 *)((int)param_1 + 0x27a) = uVar4;
    uVar3 = *(undefined1 *)*param_3;
    *param_3 = (uint)((undefined1 *)*param_3 + 1);
    *(undefined1 *)((int)param_1 + 0x3a) = uVar3;
    uVar11 = *param_3;
    *param_3 = uVar11 + 0x51;
    if (local_22c < 0x203) {
      if (local_22c < 0x1f9) goto LAB_00579f2f;
      uVar11 = uVar11 + 0x73;
    }
    else {
      uVar11 = uVar11 + 0x7b;
    }
    *param_3 = uVar11;
  }
LAB_00579f2f:
  FUN_0057a3e0(param_1[1]);
  local_234 = (void *)0xb;
  do {
    FUN_0058c130(param_3);
    uVar11 = local_238;
    local_234 = (void *)((int)local_234 + -1);
  } while (local_234 != (void *)0x0);
  uVar3 = *(undefined1 *)*param_3;
  *param_3 = (uint)((undefined1 *)*param_3 + 1);
  *(undefined1 *)((int)param_1 + 0x1d9) = uVar3;
  uVar3 = *(undefined1 *)*param_3;
  *param_3 = (uint)((undefined1 *)*param_3 + 1);
  *(undefined1 *)((int)param_1 + 0x1da) = uVar3;
  uVar3 = *(undefined1 *)*param_3;
  *param_3 = (uint)((undefined1 *)*param_3 + 1);
  *(undefined1 *)((int)param_1 + 0x1db) = uVar3;
  uVar3 = *(undefined1 *)*param_3;
  *param_3 = (uint)((undefined1 *)*param_3 + 1);
  *(undefined1 *)(param_1 + 0x77) = uVar3;
  uVar3 = *(undefined1 *)*param_3;
  *param_3 = (uint)((undefined1 *)*param_3 + 1);
  *(undefined1 *)((int)param_1 + 0x1dd) = uVar3;
  uVar3 = *(undefined1 *)*param_3;
  *param_3 = (uint)((undefined1 *)*param_3 + 1);
  *(undefined1 *)((int)param_1 + 0x1de) = uVar3;
  uVar3 = *(undefined1 *)*param_3;
  *param_3 = (uint)((undefined1 *)*param_3 + 1);
  *(undefined1 *)((int)param_1 + 0x1df) = uVar3;
  cVar15 = *(char *)*param_3;
  *param_3 = (uint)((char *)*param_3 + 1);
  local_234 = (void *)0x0;
  while (cVar15 == '\x02') {
    local_238 = uVar11;
    FUN_00579170(pvVar9,&local_238,param_3,local_230);
    cVar15 = *(char *)*param_3;
    *param_3 = (uint)((char *)*param_3 + 1);
  }
  param_1[10] = 0;
  do {
    local_228 = operator_new(0x104);
    local_4 = 0;
    if (local_228 == (void *)0x0) {
      local_234 = (void *)0x0;
    }
    else {
      local_234 = (void *)FUN_00581c80(param_1[4]);
    }
    local_4 = 0xffffffff;
    if (local_234 == (void *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    local_228 = (void *)local_238;
    do {
      local_238 = (uint)local_228;
      if (local_22c < 600) {
        iVar10 = FUN_005820f0(pvVar9,&local_238,param_3,local_22c,local_230);
        cVar15 = *(char *)*param_3;
        local_218 = CONCAT31(local_218._1_3_,cVar15);
        *param_3 = (uint)((char *)*param_3 + 1);
      }
      else {
        cVar15 = *(char *)*param_3;
        local_224 = CONCAT31(local_224._1_3_,cVar15);
        *param_3 = (uint)((char *)*param_3 + 1);
        if (cVar15 == '\0') {
          iVar10 = 0;
        }
        else {
          iVar10 = FUN_00581f80(cVar15);
        }
      }
      pvVar8 = local_234;
    } while ((cVar15 != '\0') && (pvVar9 = local_21c, iVar10 == 0));
    if (iVar10 == 0) {
      if (local_234 != (void *)0x0) {
        FUN_00581d70();
        operator_delete(pvVar8);
      }
    }
    else {
      uVar11 = (uint)*(byte *)((int)local_234 + 0x1b);
      if ((uVar11 != 0) && (uVar11 < 0xc)) {
        *(char *)(uVar11 + 0x297 + (int)param_1) = *(char *)((int)local_234 + 0x1d) + '\x01';
      }
      param_1[10] = param_1[10] + 1;
      *(int *)((int)local_234 + 0x100) = param_1[9];
      param_1[9] = (int)local_234;
    }
    pvVar9 = local_21c;
  } while (cVar15 != '\0');
LAB_0057a137:
  if (((local_238 <= local_214) && (param_3[1] != 0)) && (*param_3 <= param_3[2] + param_3[1])) {
    ExceptionList = local_c;
    return 1;
  }
  ExceptionList = local_c;
  return 0;
}


