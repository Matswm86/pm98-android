// FUN_005a2830  entry=005a2830  size=2694 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 * __thiscall
FUN_005a2830(undefined4 *param_1,int param_2,undefined4 param_3,int param_4,undefined4 param_5)

{
  byte bVar1;
  undefined4 uVar2;
  int iVar3;
  LPCSTR pCVar4;
  uint uVar5;
  int iVar6;
  undefined1 *puVar7;
  undefined1 *puVar8;
  byte bVar9;
  int iVar10;
  char *pcVar11;
  undefined4 *puVar12;
  undefined4 *puVar13;
  bool bVar14;
  char *pcVar15;
  int local_52c;
  int local_520;
  int local_51c;
  int local_518;
  int local_514;
  undefined4 *local_510;
  CHAR local_50c [256];
  CHAR local_40c [256];
  CHAR local_30c [256];
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00620d08;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *(undefined1 *)(param_1 + 7) = 0;
  *param_1 = &PTR_FUN_00639224;
  local_510 = param_1;
  FUN_00590aa0(0,0,0);
  param_1[0xb] = 0;
  param_1[0xc] = 0;
  *(undefined2 *)(param_1 + 0xd) = 0;
  FUN_005b1190(0);
  *param_1 = &PTR_FUN_00639238;
  local_4 = 0;
  param_1[0x61] = param_4 + 0x46c + param_2 * 800;
  param_1[0x62] = param_4 + param_2 * -800 + 0x78c;
  param_1[99] = param_4;
  param_1[100] = param_4 + 0x1610;
  FUN_005c9210();
  param_1[0x86] = 0x70000000;
  param_1[0x85] = 0x70000000;
  param_1[0x84] = 0x70000000;
  param_1[0x89] = 0x90000000;
  param_1[0x88] = 0x90000000;
  param_1[0x87] = 0x90000000;
  param_1[0x8b] = 0x70000000;
  param_1[0x8a] = 0x70000000;
  param_1[0x8d] = 0x90000000;
  param_1[0x8c] = 0x90000000;
  *(undefined1 *)(param_1 + 0x8e) = 0;
  param_1[0xae] = param_2;
  param_1[0xaf] = param_3;
  param_1[0xec] = 0;
  param_1[0xed] = 0;
  param_1[0xee] = param_5;
  *param_1 = &PTR_FUN_00639228;
  uVar5 = (uint)*(ushort *)(param_1[0xee] + 4);
  local_4 = CONCAT31(local_4._1_3_,3);
  lstrcpyA(local_30c,&DAT_006657a8);
  pcVar15 = &DAT_00652f00;
  iVar3 = lstrlenA(local_30c);
  sprintf(local_30c + iVar3,pcVar15,uVar5);
  FUN_0051fd00(local_30c);
  pCVar4 = (LPCSTR)FUN_005e5ce0(0xfffffffb);
  lstrcpyA(local_50c,s_DBDat_MiniFoto_J96_00665794);
  iVar3 = lstrlenA(local_50c);
  lstrcpyA(local_50c + iVar3,pCVar4);
  FUN_0051fd00(local_50c);
  pCVar4 = &DAT_0066578c;
  iVar3 = lstrlenA(local_40c);
  lstrcpyA(local_40c + iVar3,pCVar4);
  lstrcpyA(local_20c,local_40c);
  param_1[0xb0] = (uint)*(ushort *)(param_1[0xee] + 4);
  lstrcpyA((LPSTR)(param_1 + 0x8e),*(LPCSTR *)param_1[0xee]);
  param_1[0xb3] = *(undefined4 *)(param_1[0xee] + 0x28);
  uVar2 = *(undefined4 *)(param_1[0xee] + 0xc);
  param_1[0x7e] = *(undefined4 *)(param_1[0xee] + 8);
  param_1[0x7f] = uVar2;
  param_1[0x80] = 0;
  uVar2 = *(undefined4 *)(param_1[0xee] + 0x14);
  param_1[0x81] = *(undefined4 *)(param_1[0xee] + 0x10);
  param_1[0x82] = uVar2;
  param_1[0x83] = 0;
  iVar3 = param_1[0xee];
  param_1[0x8a] = *(undefined4 *)(iVar3 + 0x18);
  param_1[0x8b] = *(undefined4 *)(iVar3 + 0x1c);
  param_1[0x8c] = *(undefined4 *)(iVar3 + 0x20);
  param_1[0x8d] = *(undefined4 *)(iVar3 + 0x24);
  *(bool *)((int)param_1 + 0x2da) = *(int *)(param_1[0xee] + 0x98) != 0;
  *(undefined1 *)((int)param_1 + 0x2d9) = 0;
  param_1[0x2b] = 0;
  param_1[0x20] = 0;
  param_1[0x21] = 0;
  bVar14 = DAT_00674628 == '\0';
  DAT_00674628 = '\x01';
  if (bVar14) {
    iVar10 = 0;
    iVar3 = 0;
    do {
      *(int *)((int)&DAT_006744e8 + iVar3) = iVar10;
      if (0 < *(int *)((int)&DAT_006650e0 + iVar3)) {
        iVar10 = iVar10 + *(int *)((int)&DAT_00664fb8 + iVar3) *
                          *(int *)((int)&DAT_006650e0 + iVar3);
      }
      iVar3 = iVar3 + 4;
    } while (iVar3 < 0x124);
    _DAT_00665174 = DAT_00665170;
    _DAT_0066504c = DAT_00665048;
    _DAT_0067457c = DAT_00674578;
  }
  param_1[0xb1] = ((int)param_1 - *(int *)param_1[0x61]) / 0x3bc;
  *(undefined1 *)((int)param_1 + 99) = 0;
  *(undefined1 *)((int)param_1 + 0x2d5) = 1;
  *(bool *)(param_1 + 0xb5) = param_1[0xaf] != 0;
  param_1[0xb7] =
       ((uint)(param_1[0xaf] == 0) + param_1[0xae] * 2) * 0x100 + *(int *)(param_1[99] + 0x1a5c);
  param_1[0xdb] = *(int *)(param_1[0xee] + 0x30) + -1;
  param_1[0xdc] = *(int *)(param_1[0xee] + 0x2c) + -1;
  bVar1 = *(byte *)(param_1[0xee] + 0x42);
  bVar9 = bVar1;
  if (0x3b < bVar1) {
    bVar9 = 0x3c;
  }
  if (bVar9 == 0) {
    uVar5 = 1;
  }
  else if (bVar1 < 0x3c) {
    uVar5 = (uint)bVar1;
  }
  else {
    uVar5 = 0x3c;
  }
  param_1[0xb4] = uVar5;
  iVar3 = *(int *)(param_1[99] + 0x2550) + -0x40 + uVar5 * 0x40;
  iVar10 = 0;
  do {
    iVar6 = iVar10 + 1;
    *(char *)(iVar10 + 0x360 + (int)param_1) =
         s_HIJKLMNOXYZ_____PQRSTUVW_006653a8[param_1[0xdc] * 8 + iVar10];
    iVar10 = iVar6;
  } while (iVar6 < 8);
  if (param_1[0xdb] == 1) {
    *(undefined1 *)((int)param_1 + 0x367) = *(undefined1 *)((int)param_1 + 0x365);
    *(undefined1 *)((int)param_1 + 0x366) = *(undefined1 *)((int)param_1 + 0x365);
    param_1[0xdb] = param_1[0xdc] + 6;
  }
  iVar10 = 0;
  do {
    iVar6 = iVar10 + 1;
    *(undefined *)(iVar10 + 0x368 + (int)param_1) = (&DAT_00665380)[param_1[0xdb] * 4 + iVar10];
    iVar10 = iVar6;
  } while (iVar6 < 4);
  puVar13 = (undefined4 *)(param_1[0x61] + 0x216);
  puVar12 = param_1 + 0xb8;
  for (iVar10 = 0x20; iVar10 != 0; iVar10 = iVar10 + -1) {
    *puVar12 = *puVar13;
    puVar13 = puVar13 + 1;
    puVar12 = puVar12 + 1;
  }
  puVar8 = (undefined1 *)((int)param_1 + 0x2fa);
  pcVar15 = (char *)(iVar3 + 9);
  local_52c = 6;
  do {
    iVar10 = 6;
    puVar7 = puVar8;
    pcVar11 = pcVar15;
    do {
      if (*pcVar11 != '\0') {
        puVar7[-2] = *(undefined1 *)(param_1[0x61] + 0x2d6);
        *puVar7 = *(undefined1 *)(param_1[0x61] + 0x2d6);
        puVar7[-0x11] = *(undefined1 *)(param_1[0x61] + 0x2d6);
        puVar7[0xf] = *(undefined1 *)(param_1[0x61] + 0x2d6);
      }
      pcVar11 = pcVar11 + 8;
      puVar7 = puVar7 + 0x10;
      iVar10 = iVar10 + -1;
    } while (iVar10 != 0);
    pcVar15 = pcVar15 + 1;
    puVar8 = puVar8 + 1;
    local_52c = local_52c + -1;
  } while (local_52c != 0);
  puVar13 = param_1 + 0xba;
  iVar10 = 0;
  do {
    iVar6 = 8;
    pcVar15 = (char *)(iVar3 + iVar10);
    puVar12 = puVar13;
    do {
      if (*pcVar15 != '\0') {
        *(undefined1 *)puVar12 = *(undefined1 *)(param_1[0x61] + 0x2d8);
      }
      pcVar15 = pcVar15 + 8;
      puVar12 = puVar12 + 4;
      iVar6 = iVar6 + -1;
    } while (iVar6 != 0);
    iVar10 = iVar10 + 1;
    puVar13 = (undefined4 *)((int)puVar13 + 1);
  } while (iVar10 < 8);
  iVar3 = *(int *)(param_1[99] + 0x1820);
  if ((*(uint *)(param_1[99] + 0x19a0) & 1) == param_1[0xae]) {
    iVar3 = -iVar3;
  }
  param_1[0xe9] = iVar3;
  param_1[0x10] = -(uint)(param_1[0xaf] == 0) & 0x1e;
  param_1[0xc] = 0;
  param_1[0xb] = param_1[0xaf];
  *(undefined1 *)(param_1 + 0x17) = 0;
  *(undefined1 *)((int)param_1 + 0x5d) = 0;
  param_1[0xb2] = *(undefined4 *)(param_1[0xee] + 0x44);
  iVar3 = param_1[0xee];
  iVar10 = param_1[0xaf];
  param_1[0xde] = (uint)*(byte *)(iVar3 + 0x34);
  if (iVar10 != 0) {
    uVar5 = (uint)*(byte *)(iVar3 + 0x35);
  }
  else {
    uVar5 = (*(byte *)(iVar3 + 0x35) + 200) / 3;
  }
  param_1[0xdf] = uVar5;
  param_1[0xe0] = (uint)*(byte *)(iVar3 + 0x36);
  uVar5 = ftol();
  param_1[0xe1] = uVar5 & 0xff;
  param_1[0xe2] = (uint)*(byte *)(iVar3 + 0x38);
  param_1[0xe3] = (uint)*(byte *)(iVar3 + 0x3c);
  param_1[0xe4] = (uint)*(byte *)(iVar3 + 0x3d);
  if (iVar10 != 0) {
    uVar5 = (uint)*(byte *)(iVar3 + 0x3e);
  }
  else {
    uVar5 = 100;
  }
  param_1[0xe5] = uVar5;
  param_1[0xe6] = (uint)*(byte *)(iVar3 + 0x3f);
  param_1[0xe7] = (uint)*(byte *)(iVar3 + 0x40);
  bVar1 = *(byte *)(iVar3 + 0x41);
  param_1[0x12] = 0;
  param_1[0xe8] = (uint)bVar1;
  param_1[0x2c] = 0;
  param_1[0x2d] = 0;
  *(undefined1 *)((int)param_1 + 0x61) = 0;
  param_1[0x1b] = 0;
  param_1[0x1a] = 0;
  param_1[8] = 0;
  param_1[9] = 0;
  param_1[10] = 0;
  iVar3 = param_1[0xdf];
  iVar10 = param_1[99];
  param_1[0xea] = ((iVar3 * 0x1333) / 100 + 0x1333) / 2;
  param_1[0xeb] = ((iVar3 * 0xc5f) / 100 + 0xc5f) / 2;
  param_1[0x1d] = param_1[0xde] * 0x8c;
  param_1[0x1c] = param_1[0xde] * 0x8c;
  param_1[0x1e] = 0x78 - (int)param_1[0xe0] / 3;
  if (*(int *)(iVar10 + 0x19a0) == 4) {
    iVar6 = (param_1[0xe3] + 100) / 2;
  }
  else {
    iVar6 = (param_1[0xe3] + 200) / 3;
  }
  param_1[0xe3] = iVar6;
  param_1[0xe8] =
       ((36000 - *(int *)(iVar10 + 0x19ac)) * (100 - param_1[0xe8])) / 0xe100 + param_1[0xe8];
  param_1[0xe7] =
       ((36000 - *(int *)(iVar10 + 0x19ac)) * (100 - param_1[0xe7])) / 0xe100 + param_1[0xe7];
  param_1[0xe2] =
       ((36000 - *(int *)(iVar10 + 0x19ac)) * (100 - param_1[0xe2])) / 0xe100 + param_1[0xe2];
  param_1[0xdf] = ((36000 - *(int *)(iVar10 + 0x19ac)) * (100 - iVar3)) / 0xe100 + iVar3;
  if (*(char *)(param_1[0x61] + 0x2ec) == '\0') {
    param_1[0xe3] = (iVar6 * 0x5f) / 100;
    param_1[0xe8] = (param_1[0xe8] * 0x5f) / 100;
    param_1[0xe7] = (param_1[0xe7] * 0x5f) / 100;
    param_1[0xe5] = (param_1[0xe5] * 0x5f) / 100;
    param_1[0xe2] = (param_1[0xe2] * 0x5f) / 100;
  }
  param_1[0x13] = 0;
  param_1[0x14] = 0;
  param_1[0x22] = 0;
  *(undefined1 *)((int)param_1 + 0x2d6) = 0;
  param_1[0x15] = 0;
  param_1[0x16] = 0;
  *(undefined2 *)(param_1 + 0xd) = 0;
  param_1[1] = 0;
  param_1[2] = 0;
  param_1[3] = 0;
  param_1[0x23] = 0;
  iVar3 = FUN_005ec1d0(local_20c);
  if (iVar3 != 0) {
    FUN_005c9f60(local_20c,0,0xffffffff);
    local_520 = param_1[0x6f] - param_1[0x73];
    local_51c = param_1[0x70] - param_1[0x74];
    local_518 = param_1[0x71] - param_1[0x73];
    local_514 = param_1[0x72] - param_1[0x74];
    FUN_005d4ac0(&local_520,param_1[99] + 0x2368);
  }
  if (param_1[0xaf] == 0) {
    param_1[0xb2] = 1;
  }
  else if (param_1[0xb2] == 1) {
    param_1[0xb2] = 2;
  }
  iVar3 = 0;
  do {
    iVar10 = param_1[0x61];
    if (*(int *)(iVar3 + 0x18 + iVar10) == param_1[0xb0]) {
      param_1[0x13] = *(undefined4 *)(iVar3 + 0x1c + iVar10);
      param_1[0x14] = *(undefined4 *)(iVar3 + 0x20 + iVar10);
      *(undefined4 *)(iVar3 + 0x18 + iVar10) = 0xffffffff;
    }
    iVar3 = iVar3 + 0xc;
  } while (iVar3 < 0x84);
  param_1[0x60] = 0;
  param_1[0x5f] = 0;
  ExceptionList = local_c;
  return param_1;
}


