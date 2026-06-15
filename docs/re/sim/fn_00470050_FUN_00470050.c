// FUN_00470050  entry=00470050  size=1426 bytes
// callers/callees expanded one level from seeds

undefined4 __thiscall
FUN_00470050(undefined4 *param_1,undefined4 param_2,undefined4 param_3,int param_4)

{
  int *piVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  int iVar4;
  uint uVar5;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined4 extraout_ECX_01;
  undefined4 extraout_ECX_02;
  undefined4 extraout_ECX_03;
  int extraout_ECX_04;
  undefined4 extraout_ECX_05;
  undefined4 extraout_ECX_06;
  int iVar6;
  uint uVar7;
  int iVar8;
  char *pcVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  undefined1 *puVar12;
  undefined4 uVar13;
  undefined4 uVar14;
  undefined4 *puVar15;
  CHAR local_138 [4];
  short sStack_d0;
  int iStack_bc;
  int iStack_b8;
  uint uStack_98;
  short sStack_7c;
  undefined1 auStack_6c [16];
  undefined4 uStack_5c;
  undefined1 auStack_58 [32];
  undefined1 auStack_38 [28];
  undefined1 auStack_1c [8];
  int iStack_14;
  
  *param_1 = param_2;
  local_138[0] = '\0';
  local_138[1] = '\0';
  local_138[2] = '\0';
  local_138[3] = '\0';
  iVar4 = param_1[1];
  puVar15 = param_1;
  FUN_00436270(0);
  uVar14 = 0;
  uVar13 = 0;
  puVar12 = &DAT_00666f70;
  uVar2 = FUN_00436fb0(0x19c,0x3e);
  uVar3 = FUN_00436fb0(param_3,param_4 + -0x3d);
  uVar2 = FUN_00436fd0(uVar3,uVar2);
  (**(code **)(iVar4 + 0xc0))(param_2,uVar2,puVar12,uVar13,uVar14,puVar15);
  piVar1 = param_1 + 0xfe;
  uVar11 = 0xffffff;
  iVar4 = *piVar1;
  uVar2 = extraout_ECX;
  FUN_00436270(0xffffff);
  uVar10 = 0;
  uVar14 = 0;
  puVar12 = &DAT_00666f70;
  uVar3 = FUN_00436fb0(0x198,0x3a);
  uVar13 = FUN_00436fb0(2,2);
  uVar3 = FUN_00436fd0(uVar13,uVar3);
  (**(code **)(iVar4 + 0xc0))(param_1 + 1,uVar3,puVar12,uVar14,uVar10,uVar2,uVar11);
  lstrcpyA(local_138,s_WINNER_00653f8c);
  uVar2 = extraout_ECX_00;
  if (iStack_14 != 0) {
    pcVar9 = s__on_penalties__00653f7c;
    iVar4 = lstrlenA(local_138);
    lstrcpyA(local_138 + iVar4,pcVar9);
    uVar2 = extraout_ECX_01;
  }
  uVar3 = 0xffffffff;
  iVar4 = param_1[0x4f2];
  FUN_004ac740(auStack_1c);
  uVar2 = FUN_005c8f80(0x820,0,uVar2,uVar3);
  uVar3 = FUN_00436fb0(0x138,0x14);
  uVar13 = FUN_00436fb0(0x34,2);
  uVar3 = FUN_00436fd0(uVar13,uVar3);
  (**(code **)(iVar4 + 0xc0))(piVar1,uVar3,uVar2);
  FUN_005beae0(s_Proman14_00652ebc);
  param_1[0x5f1] = 0;
  param_1[0x51d] = param_1[0x51d] | 8;
  uVar11 = 0xffffffff;
  iVar4 = param_1[0x804];
  uVar2 = extraout_ECX_02;
  FUN_004ac740(auStack_38);
  uVar10 = 0;
  uVar14 = 0x820;
  puVar12 = &DAT_00666f70;
  uVar3 = FUN_00436fb0(0xb8,0xd);
  uVar13 = FUN_00436fb0(0xd2,6);
  uVar3 = FUN_00436fd0(uVar13,uVar3);
  (**(code **)(iVar4 + 0xc0))(piVar1,uVar3,puVar12,uVar14,uVar10,uVar2,uVar11);
  FUN_005beae0(s_Proman12_00652eb0);
  param_1[0x903] = 0;
  iVar4 = *(int *)(param_1 + 0x5f8);
  uVar2 = uStack_5c;
  FUN_004ac740(auStack_58);
  uVar10 = 0;
  uVar14 = 0x20;
  puVar12 = &DAT_00666f70;
  uVar3 = FUN_00436fb0(0x17a,0x11);
  uVar13 = FUN_00436fb0(0x17,0x1a);
  uVar3 = FUN_00436fd0(uVar13,uVar3);
  (**(code **)(iVar4 + 0xc0))(piVar1,uVar3,puVar12,uVar14,uVar10,uStack_5c,uVar2);
  if (sStack_7c != 0) {
    FUN_00585ee0(sStack_7c);
    pcVar9 = (char *)FUN_00579390();
    CString::operator=((CString *)(param_1 + 0x626),pcVar9);
    if (param_1[0x600] != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0x5f8),pcVar9);
    }
    FUN_005bec80(0);
  }
  FUN_005beae0(s_Proman14_00652ebc);
  param_1[0x6f7] = 0x1d;
  param_1[0x623] = param_1[0x623] | 8;
  uVar11 = 0xffffffff;
  iVar4 = *(int *)(param_1 + 0x6fe);
  uVar2 = extraout_ECX_03;
  FUN_004ac740(auStack_6c);
  uVar10 = 0;
  uVar14 = 0x820;
  puVar12 = &DAT_00666f70;
  uVar3 = FUN_00436fb0(0x158,0xd);
  uVar13 = FUN_00436fb0(0x35,0x2c);
  uVar3 = FUN_00436fd0(uVar13,uVar3);
  (**(code **)(iVar4 + 0xc0))(piVar1,uVar3,puVar12,uVar14,uVar10,uVar2,uVar11);
  param_1[0x7fd] = 0;
  FUN_005beae0(s_Proman12_00652eb0);
  iVar4 = extraout_ECX_04;
  if (0 < DAT_0066c17c) {
    iVar8 = 0;
    uVar5 = uStack_98 & 0xffff;
    iVar4 = 0;
    uVar7 = uVar5;
    do {
      pcVar9 = (char *)(DAT_0066c178 + iVar8);
      if (*(uint *)(DAT_0066c178 + 0x24 + iVar8) == uVar5) {
        CString::operator=((CString *)(param_1 + 0x72c),pcVar9);
        uVar5 = uVar7;
        if (param_1[0x706] != 0) {
          CWnd::SetWindowTextA((CWnd *)(param_1 + 0x6fe),pcVar9);
          uVar5 = uVar7;
        }
        FUN_005bec80(0);
        uVar7 = uVar5;
      }
      iVar4 = iVar4 + 1;
      iVar8 = iVar8 + 0x9c;
    } while (iVar4 < DAT_0066c17c);
  }
  uVar10 = 0xffffffff;
  iVar8 = param_1[0x1fb];
  FUN_00436270(0xffffffff);
  uVar14 = 0;
  uVar13 = 0x800;
  puVar12 = &DAT_00666f70;
  uVar2 = FUN_00436fb0(0x2c,0x2c);
  uVar3 = FUN_00436fb0(4,5);
  uVar2 = FUN_00436fd0(uVar3,uVar2);
  (**(code **)(iVar8 + 0xc0))(piVar1,uVar2,puVar12,uVar13,uVar14,iVar4,uVar10);
  FUN_005c06d0(s_img_resultados_final_balon_bmp_00653f5c,0,0x20,0x32,0);
  uVar11 = 0xffffffff;
  iVar4 = param_1[0x2f8];
  uVar2 = extraout_ECX_05;
  FUN_00436270(0xffffffff);
  uVar10 = 0;
  uVar14 = 0x800;
  puVar12 = &DAT_00666f70;
  uVar3 = FUN_00436fb0(0x74,0x74);
  uVar13 = FUN_00436fb0(iStack_bc + 0x167,iStack_b8 + -0x69);
  uVar3 = FUN_00436fd0(uVar13,uVar3);
  (**(code **)(iVar4 + 0xc0))(*param_1,uVar3,puVar12,uVar14,uVar10,uVar2,uVar11);
  FUN_005c06d0(s_img_resultados_final_laurel_bmp_00653f3c,0,0x20,0x32,0);
  if (sStack_d0 != 0) {
    FUN_00585ee0(sStack_d0);
    uVar3 = FUN_005796f0();
    uVar13 = 0xffffffff;
    iVar4 = param_1[0x3f5];
    uVar2 = extraout_ECX_06;
    FUN_00436270(0xffffffff);
    uVar2 = FUN_00470720(&DAT_00666f70,0x800,0,uVar2,uVar13);
    uVar13 = FUN_00470710(uVar2);
    uVar2 = FUN_00436fb0(uVar13,uVar2);
    iVar8 = FUN_00470720(uVar2);
    iVar6 = 0x33 - iVar8 / 2;
    iVar8 = FUN_00470710(iVar6);
    uVar13 = FUN_00436fb0(0x35 - iVar8 / 2,iVar6);
    uVar2 = FUN_00436fd0(uVar13,uVar2);
    (**(code **)(iVar4 + 0xc0))(param_1 + 0x2f8,uVar2);
    FUN_005c0d50(uVar3,0,0x20,0x32,0);
    *(undefined1 *)(param_1 + 0x40e) = 0x20;
    *(undefined1 *)((int)param_1 + 0x103a) = 0x80;
  }
  return 1;
}


