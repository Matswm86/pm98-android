// FUN_005820f0  entry=005820f0  size=1212 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int __thiscall
FUN_005820f0(ushort *param_1,int param_2,int *param_3,int *param_4,uint param_5,int param_6)

{
  undefined1 uVar1;
  byte bVar2;
  char *pcVar3;
  char cVar4;
  short sVar5;
  int iVar6;
  char cVar7;
  uint uVar8;
  ushort *puVar9;
  ushort uVar10;
  int local_8;
  int local_4;
  
  local_8 = *param_3;
  uVar10 = *(ushort *)*param_4;
  *param_4 = (int)((ushort *)*param_4 + 1);
  *param_1 = uVar10;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  iVar6 = local_8 + param_2;
  *(undefined1 *)(param_1 + 0x7c) = uVar1;
  *(int *)(param_1 + 2) = iVar6;
  iVar6 = FUN_0058c810(iVar6);
  local_8 = local_8 + iVar6;
  iVar6 = local_8 + param_2;
  *(int *)(param_1 + 4) = iVar6;
  iVar6 = FUN_0058c810(iVar6);
  local_8 = local_8 + iVar6;
  bVar2 = *(byte *)*param_4;
  *param_4 = (int)((byte *)*param_4 + 1);
  *(byte *)((int)param_1 + 0x19) = bVar2;
  *(byte *)((int)param_1 + 0x1b) = bVar2;
  if ((bVar2 < 0x62) && (param_1[1] != 0x26de)) {
    local_4 = 1;
  }
  else {
    local_4 = 0;
    if (599 < param_5) {
      return 0;
    }
  }
  uVar8 = 0;
  *param_4 = *param_4 + 1;
  do {
    cVar4 = *(char *)*param_4;
    *param_4 = (int)((char *)*param_4 + 1);
    if (cVar4 == '\0') {
      cVar4 = 'b';
    }
    else {
      cVar4 = cVar4 + -1;
    }
    *(char *)(uVar8 + 0x1d + (int)param_1) = cVar4;
    uVar8 = uVar8 + 1;
  } while (uVar8 < 6);
  *(undefined1 *)(param_1 + 0xc) = *(undefined1 *)((int)param_1 + 0x1d);
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)(param_1 + 0xd) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)(param_1 + 0xb) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)((int)param_1 + 0x17) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)(param_1 + 0xe) = uVar1;
  pcVar3 = (char *)*param_4;
  cVar4 = *pcVar3;
  *param_4 = (int)(pcVar3 + 1);
  cVar7 = pcVar3[1];
  *param_4 = (int)(pcVar3 + 2);
  uVar10 = *(ushort *)(pcVar3 + 2);
  *param_4 = (int)(pcVar3 + 4);
  if (cVar4 == '\0') {
    cVar4 = (char)((uint)_DAT_0066b18c >> 0x10);
  }
  if (cVar7 == '\0') {
    cVar7 = (char)((uint)_DAT_0066b18c >> 0x18);
  }
  if ((uVar10 < 0x76d) || (0x7c1 < uVar10)) {
    sVar5 = FUN_0058df90(5);
    uVar10 = ((short)_DAT_0066b18c + -0x19) - sVar5;
  }
  *(char *)(param_1 + 0x7f) = cVar4;
  *(char *)((int)param_1 + 0xff) = cVar7;
  param_1[0x7e] = uVar10;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)((int)param_1 + 0xf9) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)(param_1 + 0x7d) = uVar1;
  if (*(byte *)((int)param_1 + 0xf9) < 0x96) {
    cVar4 = FUN_0058df90(10);
    *(char *)((int)param_1 + 0xf9) = cVar4 + -0x56;
  }
  if ((byte)param_1[0x7d] < 0x14) {
    cVar4 = FUN_0058df90(10);
    *(char *)(param_1 + 0x7d) = cVar4 + 'K';
  }
  if (param_6 == 0) {
    puVar9 = (ushort *)(*param_4 + 1);
    *param_4 = (int)puVar9;
    *param_4 = *puVar9 + 2 + (int)puVar9;
    if (param_1[1] == 0x26ae) {
      *(int *)(param_1 + 6) = local_8 + param_2;
      iVar6 = FUN_0058c810(local_8 + param_2);
      local_8 = local_8 + iVar6;
    }
    else {
      param_1[6] = 0;
      param_1[7] = 0;
      *param_4 = *(ushort *)*param_4 + 2 + *param_4;
    }
    puVar9 = (ushort *)(*param_4 + *(ushort *)*param_4 + 2);
    *param_4 = (int)puVar9;
    puVar9 = (ushort *)(*puVar9 + 2 + (int)puVar9);
    *param_4 = (int)puVar9;
    puVar9 = (ushort *)(*puVar9 + 2 + (int)puVar9);
    *param_4 = (int)puVar9;
    puVar9 = (ushort *)(*puVar9 + 2 + (int)puVar9);
    *param_4 = (int)puVar9;
    puVar9 = (ushort *)(*puVar9 + 2 + (int)puVar9);
    *param_4 = (int)puVar9;
    puVar9 = (ushort *)(*puVar9 + 2 + (int)puVar9);
    *param_4 = (int)puVar9;
    puVar9 = (ushort *)(*puVar9 + 2 + (int)puVar9);
    *param_4 = (int)puVar9;
    *param_4 = *puVar9 + 2 + (int)puVar9;
  }
  else {
    param_1[6] = 0;
    param_1[7] = 0;
  }
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)(param_1 + 0x55) = uVar1;
  *(undefined1 *)(param_1 + 0x4e) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)((int)param_1 + 0xab) = uVar1;
  *(undefined1 *)((int)param_1 + 0x9d) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)(param_1 + 0x56) = uVar1;
  *(undefined1 *)(param_1 + 0x4f) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)((int)param_1 + 0xad) = uVar1;
  *(undefined1 *)((int)param_1 + 0x9f) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)((int)param_1 + 0xb1) = uVar1;
  *(undefined1 *)((int)param_1 + 0xa3) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)(param_1 + 0x59) = uVar1;
  *(undefined1 *)(param_1 + 0x52) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)(param_1 + 0x58) = uVar1;
  *(undefined1 *)(param_1 + 0x51) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)((int)param_1 + 0xb3) = uVar1;
  *(undefined1 *)((int)param_1 + 0xa5) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)((int)param_1 + 0xaf) = uVar1;
  *(undefined1 *)((int)param_1 + 0xa1) = uVar1;
  uVar1 = *(undefined1 *)*param_4;
  *param_4 = (int)((undefined1 *)*param_4 + 1);
  *(undefined1 *)(param_1 + 0x57) = uVar1;
  *(undefined1 *)(param_1 + 0x50) = uVar1;
  if (param_1[10] == 0x26e4) {
    iVar6 = FUN_0058df90(0xb);
    uVar8 = iVar6 + 0x23;
    cVar4 = (char)uVar8;
    if (uVar8 < (byte)param_1[0x4e]) {
      cVar7 = (byte)param_1[0x4e] - cVar4;
    }
    else {
      cVar7 = '\0';
    }
    *(char *)(param_1 + 0x4e) = cVar7;
    if (uVar8 < *(byte *)((int)param_1 + 0x9d)) {
      cVar7 = *(byte *)((int)param_1 + 0x9d) - cVar4;
    }
    else {
      cVar7 = '\0';
    }
    *(char *)((int)param_1 + 0x9d) = cVar7;
    if (uVar8 < (byte)param_1[0x4f]) {
      cVar7 = (byte)param_1[0x4f] - cVar4;
    }
    else {
      cVar7 = '\0';
    }
    *(char *)(param_1 + 0x4f) = cVar7;
    if (uVar8 < *(byte *)((int)param_1 + 0x9f)) {
      cVar7 = *(byte *)((int)param_1 + 0x9f) - cVar4;
    }
    else {
      cVar7 = '\0';
    }
    *(char *)((int)param_1 + 0x9f) = cVar7;
    if (uVar8 < *(byte *)((int)param_1 + 0xa3)) {
      cVar7 = *(byte *)((int)param_1 + 0xa3) - cVar4;
    }
    else {
      cVar7 = '\0';
    }
    *(char *)((int)param_1 + 0xa3) = cVar7;
    if (uVar8 < (byte)param_1[0x52]) {
      cVar7 = (byte)param_1[0x52] - cVar4;
    }
    else {
      cVar7 = '\0';
    }
    *(char *)(param_1 + 0x52) = cVar7;
    if (uVar8 < (byte)param_1[0x51]) {
      cVar7 = (byte)param_1[0x51] - cVar4;
    }
    else {
      cVar7 = '\0';
    }
    *(char *)(param_1 + 0x51) = cVar7;
    if (uVar8 < *(byte *)((int)param_1 + 0xa5)) {
      cVar7 = *(byte *)((int)param_1 + 0xa5) - cVar4;
    }
    else {
      cVar7 = '\0';
    }
    *(char *)((int)param_1 + 0xa5) = cVar7;
    if (uVar8 < *(byte *)((int)param_1 + 0xa1)) {
      cVar7 = *(byte *)((int)param_1 + 0xa1) - cVar4;
    }
    else {
      cVar7 = '\0';
    }
    *(char *)((int)param_1 + 0xa1) = cVar7;
    if (uVar8 < (byte)param_1[0x50]) {
      cVar4 = (byte)param_1[0x50] - cVar4;
    }
    else {
      cVar4 = '\0';
    }
    *(char *)(param_1 + 0x50) = cVar4;
  }
  *param_3 = local_8;
  if (local_4 == 0) {
    return 0;
  }
  uVar10 = *param_1;
  if (uVar10 != 0) {
    if (uVar10 < DAT_0066c150) {
      puVar9 = *(ushort **)(DAT_0066c158 + (uint)uVar10 * 4);
    }
    else {
      puVar9 = (ushort *)0x0;
    }
    if ((puVar9 == (ushort *)0x0) || (puVar9 == param_1)) goto LAB_00582593;
  }
  uVar10 = (ushort)DAT_0066c154;
  DAT_0066c154 = DAT_0066c154 + 1;
  *param_1 = uVar10;
LAB_00582593:
  FUN_00586b40(param_1);
  return local_4;
}


