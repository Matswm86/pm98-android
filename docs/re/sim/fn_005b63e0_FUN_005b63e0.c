// FUN_005b63e0  entry=005b63e0  size=1974 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_005b63e0(int param_1,int param_2,int param_3,int param_4)

{
  byte bVar1;
  char cVar2;
  undefined2 uVar3;
  undefined4 uVar4;
  int iVar5;
  LPCSTR pCVar6;
  int iVar7;
  uint uVar8;
  uint uVar9;
  CHAR *pCVar10;
  undefined4 *puVar11;
  undefined4 *puVar12;
  char *_Format;
  int local_e44;
  int local_e40;
  int local_e3c;
  int local_e38;
  CHAR local_e34 [256];
  CHAR local_d34 [256];
  undefined1 local_c34;
  undefined4 local_b2c;
  undefined4 *local_b28;
  undefined4 local_b24;
  CHAR local_b20 [256];
  CHAR local_a20;
  undefined4 local_a1f;
  CHAR local_920 [256];
  CHAR local_820 [256];
  undefined1 local_720;
  undefined4 local_618;
  undefined4 *local_614;
  undefined4 local_610;
  undefined1 local_60c [256];
  undefined1 local_50c [256];
  CHAR local_40c [256];
  undefined1 local_30c [256];
  CHAR local_20c;
  undefined4 local_20b;
  undefined1 local_10c [256];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00620d8b;
  local_c = ExceptionList;
  uVar3 = *(undefined2 *)(param_3 + 0x790);
  ExceptionList = &local_c;
  lstrcpyA(local_d34,&DAT_00665844);
  FUN_005b94c0(uVar3);
  FUN_0051fd00(local_d34);
  uVar4 = FUN_005e5c50(local_820,0xfffffffc);
  lstrcpyA(local_e34,s_DatSim_paletas_P96A_00665830);
  FUN_004c4200(uVar4);
  FUN_0051fd00(local_e34);
  lstrcpyA(local_b20,local_920);
  FUN_004c4200(&DAT_00665828);
  FUN_0051fd00(local_b20);
  iVar5 = FUN_005ec1d0(local_40c);
  if (iVar5 == 0) {
    lstrcpyA(&local_a20,s_DatSim_paletas_P96A0000_DAT_0066580c);
    pCVar10 = &local_a20;
  }
  else {
    pCVar10 = local_40c;
  }
  lstrcpyA(&local_20c,pCVar10);
  pCVar6 = pCVar10 + 1;
  puVar11 = &local_20b;
  for (iVar5 = 0x3f; iVar5 != 0; iVar5 = iVar5 + -1) {
    *puVar11 = *(undefined4 *)pCVar6;
    pCVar6 = pCVar6 + 4;
    puVar11 = puVar11 + 1;
  }
  *(undefined2 *)puVar11 = *(undefined2 *)pCVar6;
  *(CHAR *)((int)puVar11 + 2) = pCVar6[2];
  uVar3 = *(undefined2 *)(param_3 + 0x790);
  lstrcpyA(local_b20,&DAT_00665844);
  FUN_005b94c0(CONCAT22((short)((uint)((int)puVar11 + 3) >> 0x10),uVar3));
  FUN_0051fd00(local_b20);
  pCVar6 = (LPCSTR)FUN_005e5c50(local_820,0xfffffffc);
  lstrcpyA(local_e34,s_DBDat_MiniEsc_EQ96_006657f8);
  iVar5 = lstrlenA(local_e34);
  lstrcpyA(local_e34 + iVar5,pCVar6);
  FUN_0051fd00(local_e34);
  lstrcpyA(local_d34,local_920);
  FUN_004c4200(&DAT_0066578c);
  FUN_0051fd00(local_d34);
  uVar3 = *(undefined2 *)(param_3 + 0x790);
  lstrcpyA(local_b20,&DAT_00665844);
  FUN_005b94c0(uVar3);
  FUN_0051fd00(local_b20);
  uVar4 = FUN_005e5c50(local_820,0xfffffffc);
  lstrcpyA(local_d34,s_DBDat_RidiEsc_EQ96_006657e4);
  FUN_004c4200(uVar4);
  FUN_0051fd00(local_d34);
  lstrcpyA(local_e34,local_920);
  FUN_004c4200(&DAT_0066578c);
  FUN_0051fd00(local_e34);
  local_720 = 0;
  local_618 = 0;
  local_614 = (undefined4 *)0x0;
  local_610 = 0;
  FUN_005ec020(&local_20c);
  *(int *)(param_1 + 8) = param_2;
  *(int *)(param_1 + 0x9c) = param_3;
  *(int *)(param_1 + 0x138) = param_4;
  local_4 = 0;
  *(bool *)(param_1 + 0x2ee) = *(int *)(param_3 + 0x798) != 0;
  puVar11 = local_614;
  puVar12 = (undefined4 *)(param_1 + 0x216);
  for (iVar5 = 0x30; iVar5 != 0; iVar5 = iVar5 + -1) {
    *puVar12 = *puVar11;
    puVar11 = puVar11 + 1;
    puVar12 = puVar12 + 1;
  }
  *(char *)(param_1 + 0x2d6) = *(char *)(param_1 + 0x2c6);
  if ((param_2 == 1) && (*(char *)(param_4 + 0x742) == *(char *)(param_1 + 0x2c6))) {
    uVar3 = *(undefined2 *)(param_3 + 0x790);
    lstrcpyA(local_b20,&DAT_00665844);
    FUN_005b94c0(uVar3);
    FUN_0051fd00(local_b20);
    pCVar6 = (LPCSTR)FUN_005e5c50(local_10c,0xfffffffc);
    lstrcpyA(local_e34,s_DatSim_paletas_P96B_006657d0);
    iVar5 = lstrlenA(local_e34);
    lstrcpyA(local_e34 + iVar5,pCVar6);
    FUN_0051fd00(local_e34);
    lstrcpyA(local_d34,local_820);
    FUN_004c4200(&DAT_00665828);
    FUN_0051fd00(local_d34);
    iVar5 = FUN_005ec1d0(local_920);
    if (iVar5 == 0) {
      lstrcpyA(local_820,s_DatSim_paletas_P96A0000_DAT_0066580c);
      pCVar10 = local_820;
    }
    else {
      pCVar10 = local_920;
    }
    lstrcpyA(&local_a20,pCVar10);
    pCVar6 = pCVar10 + 1;
    puVar11 = &local_a1f;
    for (iVar5 = 0x3f; iVar5 != 0; iVar5 = iVar5 + -1) {
      *puVar11 = *(undefined4 *)pCVar6;
      pCVar6 = pCVar6 + 4;
      puVar11 = puVar11 + 1;
    }
    *(undefined2 *)puVar11 = *(undefined2 *)pCVar6;
    local_c34 = 0;
    *(CHAR *)((int)puVar11 + 2) = pCVar6[2];
    local_b2c = 0;
    local_b28 = (undefined4 *)0x0;
    local_b24 = 0;
    FUN_005ec020(&local_a20);
    puVar11 = local_b28;
    puVar12 = (undefined4 *)(param_1 + 0x216);
    for (iVar5 = 0x30; iVar5 != 0; iVar5 = iVar5 + -1) {
      *puVar12 = *puVar11;
      puVar11 = puVar11 + 1;
      puVar12 = puVar12 + 1;
    }
    *(undefined1 *)(param_1 + 0x2d6) = *(undefined1 *)(param_1 + 0x2c6);
    FUN_005ec0e0();
  }
  bVar1 = *(byte *)(param_4 + 0x1e69 + (uint)*(byte *)(param_1 + 0x2d6) * 4);
  uVar8 = 0;
  *(undefined4 *)(param_1 + 0x2dc) = 0;
  *(byte *)(param_1 + 0x2d8) = (-(100 < bVar1) & 0xe8U) + 0x7f;
  *(bool *)(param_1 + 0x2ec) = **(int **)(param_1 + 0x9c) != 0;
  do {
    iVar5 = uVar8 + ((int)uVar8 >> 0x1f & 0xfU);
    uVar9 = uVar8 & 0xf;
    uVar8 = uVar8 + 1;
    *(undefined1 *)
     (*(int *)(*(int *)(param_1 + 0x138) + 0x1a5c) + *(int *)(param_1 + 8) * 0x200 + 8 + uVar8) =
         *(undefined1 *)(uVar9 + 0x296 + param_1 + (iVar5 >> 4) * 0x10);
  } while ((int)uVar8 < 0x30);
  do {
    do {
      iVar5 = FUN_005ec250();
      iVar5 = (int)(iVar5 * 8 + (iVar5 * 8 >> 0x1f & 0x7fffU)) >> 0xf;
      cVar2 = (&DAT_006657b0)[iVar5];
      *(char *)(param_1 + 0x2d7) = cVar2;
    } while (cVar2 == *(char *)(param_1 + 0x2d6));
  } while ((*(int *)(param_1 + 8) == 1) &&
          ((cVar2 == *(char *)(param_4 + 0x742) || (cVar2 == *(char *)(param_4 + 0x743)))));
  lstrcpyA(local_e34,s_DatSim_paletas_palpor_006657b8);
  _Format = &DAT_00652f00;
  iVar7 = lstrlenA(local_e34);
  sprintf(local_e34 + iVar7,_Format,iVar5);
  FUN_0051fd00(local_e34);
  lstrcpyA(local_d34,local_820);
  pCVar6 = &DAT_00664d44;
  iVar5 = lstrlenA(local_d34);
  lstrcpyA(local_d34 + iVar5,pCVar6);
  FUN_0051fd00(local_d34);
  local_b2c = 0;
  local_b28 = (undefined4 *)0x0;
  local_b24 = 0;
  local_c34 = 0;
  FUN_005ec020(local_60c);
  puVar11 = local_b28;
  puVar12 = (undefined4 *)
            (*(int *)(*(int *)(param_1 + 0x138) + 0x1a5c) + 0x100 + *(int *)(param_1 + 8) * 0x200);
  for (iVar5 = 0x40; iVar5 != 0; iVar5 = iVar5 + -1) {
    *puVar12 = *puVar11;
    puVar11 = puVar11 + 1;
    puVar12 = puVar12 + 1;
  }
  FUN_005ec0e0();
  iVar5 = FUN_005ec1d0(local_50c);
  if (iVar5 == 0) {
    FUN_005c9a30(2,2,8,0,0xffffffff);
  }
  else {
    FUN_005c9f60(local_50c,0,0);
    CRect::CRect((CRect *)&local_e44,*(int *)(param_1 + 200) - *(int *)(param_1 + 0xd8),
                 *(int *)(param_1 + 0xcc) - *(int *)(param_1 + 0xdc),
                 *(int *)(param_1 + 0xd0) - *(int *)(param_1 + 0xd8),
                 *(int *)(param_1 + 0xd4) - *(int *)(param_1 + 0xdc));
    FUN_005d4ac0(&local_e44,param_4 + 0x2368);
  }
  iVar5 = FUN_005ec1d0(local_30c);
  if (iVar5 == 0) {
    FUN_005c9a30(2,2,8,0,0xffffffff);
  }
  else {
    FUN_005c9f60(local_30c,0,0);
    local_e44 = *(int *)(param_1 + 0x114) - *(int *)(param_1 + 0x124);
    local_e40 = *(int *)(param_1 + 0x118) - *(int *)(param_1 + 0x128);
    local_e3c = *(int *)(param_1 + 0x11c) - *(int *)(param_1 + 0x124);
    local_e38 = *(int *)(param_1 + 0x120) - *(int *)(param_1 + 0x128);
    FUN_005d4ac0(&local_e44,param_4 + 0x2368);
  }
  *(undefined4 *)(param_1 + 0x2e4) = 0;
  *(undefined4 *)(param_1 + 0x2e8) = 0;
  puVar11 = (undefined4 *)(param_1 + 0x18);
  for (iVar5 = 0x21; iVar5 != 0; iVar5 = iVar5 + -1) {
    *puVar11 = 0;
    puVar11 = puVar11 + 1;
  }
  FUN_005b6ba0();
  local_4 = 0xffffffff;
  FUN_005ec0e0();
  ExceptionList = local_c;
  return;
}


