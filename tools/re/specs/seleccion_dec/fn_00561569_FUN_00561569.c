// FUN_00561569  entry=00561569  size=2923 bytes

int FUN_00561569(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int *piVar3;
  int iVar4;
  int *piVar5;
  uint uVar6;
  int extraout_ECX;
  int extraout_ECX_00;
  char *pcVar7;
  undefined4 extraout_ECX_01;
  uint unaff_EBX;
  uint uVar8;
  int *piVar9;
  uint uVar10;
  int unaff_ESI;
  undefined1 *puVar11;
  undefined4 uVar12;
  undefined4 uVar13;
  undefined4 uVar14;
  undefined4 uVar15;
  int iVar16;
  int iVar17;
  int iVar18;
  uint uVar19;
  char *pcStack_44;
  int iStack_40;
  int iStack_38;
  undefined4 uStack_24;
  undefined4 uStack_8;
  
  uStack_8 = 0x561573;
  FUN_005c9f60();
  *(uint *)(unaff_ESI + 0xac) = *(uint *)(unaff_ESI + 0xac) & 0xfffffff7;
  FUN_005beae0();
  if (*(uint *)(unaff_ESI + 0x1930) == unaff_EBX) {
    *(char **)(unaff_ESI + 0xccc) = s_INFOFUT_if5proma_htm_0065ffdc;
  }
  else {
    *(char **)(unaff_ESI + 0xccc) = s_INFOFUT_if5profe_htm_0065fff4;
  }
  iVar17 = *(int *)(unaff_ESI + 0x19cc);
  uStack_8 = 0x5615ca;
  FUN_00436270();
  uStack_8 = 0x820;
  FUN_00436fb0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar17 + 0xc0))();
  FUN_005beae0();
  *(undefined1 *)(unaff_ESI + 0x1a31) = 0x30;
  *(uint *)(unaff_ESI + 0x1dc8) = unaff_EBX;
  iVar17 = *(int *)(unaff_ESI + 0x1de4);
  uStack_24 = 0x56163b;
  FUN_00436270();
  uStack_24 = 0x820;
  FUN_00436fb0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar17 + 0xc0))();
  FUN_005beae0();
  *(undefined1 *)(unaff_ESI + 0x1e49) = 0x30;
  *(uint *)(unaff_ESI + 0x21e0) = unaff_EBX;
  iVar17 = *(int *)(unaff_ESI + 0x484);
  iStack_40 = 0x5616ac;
  FUN_00436270();
  iStack_40 = 0x808;
  pcStack_44 = s_OFFERS_SELECTION_0065ffbc;
  FUN_00436fb0();
  FUN_00436fb0();
  FUN_00436fd0();
  (**(code **)(iVar17 + 0xc0))();
  FUN_005beae0();
  *(uint *)(unaff_ESI + 0x880) = unaff_EBX;
  *(undefined1 *)(unaff_ESI + 0x4e9) = 0x20;
  iVar17 = *(int *)(unaff_ESI + 0x2e44);
  FUN_00437020(0xff);
  uVar1 = FUN_00436fb0(0x70,0x19);
  uVar2 = FUN_00436fb0(0x1fc,0x1b8);
  FUN_00436fd0(uVar2,uVar1);
  (**(code **)(iVar17 + 0xc0))();
  if ((~(byte)(*(uint *)(unaff_ESI + 0x2ef0) >> 7) & 1) != 0) {
    FUN_005bf8c0(unaff_EBX,1);
  }
  iVar17 = *(int *)(unaff_ESI + 0xc49c);
  FUN_00437020(0xa5,0xcb,0xf7);
  uVar1 = FUN_00436fb0(0x1b0,0x13);
  uVar2 = FUN_00436fb0(0x68,0xe4);
  FUN_00436fd0(uVar2,uVar1);
  (**(code **)(iVar17 + 0xc0))();
  FUN_005beae0(s_ProMan12_006567d4);
  iVar16 = 0x108;
  iVar17 = 0xa0;
  uVar8 = unaff_EBX;
  piVar9 = (int *)(unaff_ESI + 0x72bc);
  do {
    iVar18 = *piVar9;
    iVar4 = iVar17;
    FUN_00436270(uVar8);
    iVar17 = iVar17 + -0x14;
    uVar1 = FUN_00436fb0(0x186,0xf);
    uVar2 = FUN_00436fb0(0x92,iVar16);
    FUN_00436fd0(uVar2,uVar1);
    (**(code **)(iVar18 + 0xc0))();
    FUN_005beae0(s_ProMan8_00658928);
    piVar9[0x15] = 0;
    iVar18 = piVar9[0xa3c];
    FUN_00436270(0xffffff);
    uVar1 = FUN_00436fb0(0x2a,0xf);
    uVar2 = FUN_00436fb0(0x68,iVar17);
    FUN_00436fd0(uVar2,uVar1);
    (**(code **)(iVar18 + 0xc0))();
    uVar8 = 0;
    FUN_005c0d50(unaff_ESI + 0x1934,0,0,0x32,0);
    FUN_005c0d50(unaff_ESI + 0x1980,1,0,0x32,0);
    FUN_00437be0(&pcStack_44,piVar9 + 0xa5a);
    piVar3 = (int *)FUN_004aa3e0(&uStack_8,&pcStack_44);
    piVar9[0xa5e] = *piVar3;
    piVar9[0xa5f] = piVar3[1];
    piVar9[0xa60] = piVar3[2];
    piVar9[0xa61] = piVar3[3];
    iVar16 = iVar16 + 0xf;
    piVar9[0xa51] = 0;
    pcVar7 = DAT_0066c178;
    iVar17 = iVar4 + 1;
    piVar9 = piVar9 + 0x106;
  } while (iVar4 - 0x9fU < 10);
  if (*(int *)(unaff_ESI + 0x1930) == 0) {
    iVar17 = *(int *)(unaff_ESI + 0x21fc);
    FUN_00437020(0xff,0xdf,0);
    uVar1 = FUN_00436fb0(0x98,0x19);
    uVar2 = FUN_00436fb0(0xaf,0x1b8);
    FUN_00436fd0(uVar2,uVar1);
    (**(code **)(iVar17 + 0xc0))();
    FUN_005c06d0(s_RECURSOS_ICONOS_carga_bmp_0065faa8,0,0,0x32,0);
    iVar17 = *(int *)(unaff_ESI + 0x2614);
    FUN_00437020(0xff,0x1f,0);
    uVar1 = FUN_00436fb0(0x70,0x19);
    uVar2 = FUN_00436fb0(0x15c,0x1b8);
    FUN_00436fd0(uVar2,uVar1);
    (**(code **)(iVar17 + 0xc0))();
    FUN_005c06d0(s_recursos_iconos_seleccion_borra__00656700,0,0,0x32,0);
    iVar17 = *(int *)(unaff_ESI + 0x2a2c);
    FUN_00437020(0xff,0xff,0);
    uVar1 = FUN_00436fb0(0x70,0x19);
    uVar2 = FUN_00436fb0(0x19,0x1b8);
    FUN_00436fd0(uVar2,uVar1);
    (**(code **)(iVar17 + 0xc0))();
    uVar8 = 8;
    while (8 < DAT_0066c17c) {
      DAT_0066c17c = DAT_0066c17c - 1;
      if (DAT_0066c178 + DAT_0066c17c * 0x9c != (char *)0x0) {
        FUN_00560ba0(1);
      }
    }
    FUN_005bbf10(&DAT_0066c178,0x4e0);
    for (; DAT_0066c17c < 8; DAT_0066c17c = DAT_0066c17c + 1) {
      if (DAT_0066c178 + DAT_0066c17c * 0x9c != (char *)0x0) {
        FUN_0055e380();
      }
    }
  }
  else {
    CString::operator=((CString *)(unaff_ESI + 0xc554),DAT_0066c178);
    if (*(int *)(unaff_ESI + 0xc4bc) != 0) {
      CWnd::SetWindowTextA((CWnd *)(unaff_ESI + 0xc49c),pcVar7);
    }
    FUN_005bec80(0);
    FUN_005620e0();
    uVar8 = DAT_0066c17c;
  }
  iVar16 = 0x55;
  iVar17 = 0;
  uVar10 = 0;
  uVar19 = unaff_EBX;
  iStack_38 = extraout_ECX;
  if (uVar8 != 0) {
    iVar18 = 0x78;
    piVar9 = (int *)(unaff_ESI + 0x325c);
    piVar3 = (int *)(unaff_ESI + 0x51fc);
    uVar6 = uVar8;
    do {
      iVar17 = *piVar9;
      FUN_00436270(0xffffffff);
      iVar4 = iVar18 + -0x14;
      uVar1 = FUN_00436fb0(0x1fd,0x10);
      uVar2 = FUN_00436fb0(0x57,iVar16);
      FUN_00436fd0(uVar2,uVar1);
      (**(code **)(iVar17 + 0xc0))();
      FUN_005beae0(s_ProMan8_00658928);
      iVar17 = *piVar3;
      FUN_00436270(0xffffff);
      uVar1 = FUN_00436fb0(0x2a,0xf);
      uVar2 = FUN_00436fb0(0x2d,iVar4);
      FUN_00436fd0(uVar2,uVar1);
      (**(code **)(iVar17 + 0xc0))();
      FUN_005c0d50(unaff_ESI + 0x1934,0,0,0x32,0);
      FUN_005c0d50(unaff_ESI + 0x1980,1,0,0x32,0);
      pcStack_44 = (char *)0x19;
      unaff_EBX = 0x29;
      iStack_40 = 1;
      iStack_38 = 0xf;
      FUN_00437be0(&uStack_24,piVar3 + 0x1e);
      piVar5 = (int *)FUN_004aa3e0(&stack0x00000008,&uStack_24);
      piVar9 = piVar9 + 0xfd;
      piVar3[0x22] = *piVar5;
      piVar3[0x23] = piVar5[1];
      iVar17 = piVar5[2];
      piVar3[0x24] = iVar17;
      iVar16 = iVar16 + 0xf;
      piVar3[0x25] = piVar5[3];
      iVar18 = iVar18 + 1;
      uVar6 = uVar6 - 1;
      uVar10 = uVar8;
      piVar3 = piVar3 + 0x106;
      uVar19 = uVar8;
    } while (uVar6 != 0);
  }
  if (uVar10 < 8) {
    uVar8 = uVar10 + 0x78;
    piVar9 = (int *)(unaff_ESI + 0x325c + uVar10 * 0x3f4);
    piVar3 = (int *)(unaff_ESI + 0x5278 + uVar10 * 0x418);
    iVar17 = iVar16;
    do {
      iVar16 = *piVar9;
      piVar5 = piVar9;
      FUN_00436270(0xffffffff);
      iVar18 = uVar8 - 0x14;
      uVar1 = FUN_00436fb0(0x1fd,0x10);
      uVar2 = FUN_00436fb0(0x57,iVar17);
      FUN_00436fd0(uVar2,uVar1);
      (**(code **)(iVar16 + 0xc0))();
      FUN_005beae0(s_ProMan8_00658928);
      if ((~(byte)((uint)piVar9[0x2b] >> 7) & 1) != 0) {
        FUN_005bf8c0(0,1);
      }
      iVar16 = piVar3[-0x1f];
      FUN_00436270(0xffffff);
      uVar1 = FUN_00436fb0(0x2a,0xf);
      uVar2 = FUN_00436fb0(0x2d,iVar18);
      FUN_00436fd0(uVar2,uVar1);
      (**(code **)(iVar16 + 0xc0))();
      FUN_005c0d50(unaff_ESI + 0x1934,0,0,0x32,0);
      FUN_005c0d50(unaff_ESI + 0x1980,1,0,0x32,0);
      CRect::CRect((CRect *)&pcStack_44,0,0,piVar3[1] - piVar3[-1],piVar3[2] - *piVar3);
      iVar16 = iStack_38;
      if (0xf < iStack_38) {
        iVar16 = 0xf;
      }
      uVar10 = unaff_EBX;
      if (0x29 < (int)unaff_EBX) {
        uVar10 = 0x29;
      }
      iVar18 = iStack_40;
      if (iStack_40 < 1) {
        iVar18 = 1;
      }
      pcVar7 = pcStack_44;
      if ((int)pcStack_44 < 0x19) {
        pcVar7 = (char *)0x19;
      }
      CRect::CRect((CRect *)&stack0xffffffa4,(int)pcVar7,iVar18,uVar10,iVar16);
      piVar3[3] = uVar19;
      piVar3[4] = 0x396;
      piVar3[5] = extraout_ECX_00;
      piVar3[6] = 0xc8a0a0;
      if ((~(byte)((uint)piVar3[0xc] >> 7) & 1) != 0) {
        FUN_005bf8c0(0,1);
      }
      iVar17 = iVar17 + 0xf;
      piVar9 = piVar5 + 0xfd;
      uVar8 = uVar8 + 1;
      piVar3 = piVar3 + 0x106;
    } while (uVar8 < 0x80);
  }
  if (*(int *)(unaff_ESI + 0x1930) == 0) {
    uVar15 = 0xffffff;
    iVar16 = *(int *)(unaff_ESI + 0xccb4);
    FUN_00436270(0);
    uVar14 = 200;
    uVar13 = 0x80000;
    pcVar7 = s_OFFERS_0065c2d0;
    uVar1 = FUN_00436fb0(0x8a,0x10);
    uVar2 = FUN_00436fb0(0x77,0);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    (**(code **)(iVar16 + 0xc0))(unaff_ESI + 0x325c,uVar1,pcVar7,uVar13,uVar14,iVar17,uVar15);
    if ((~(byte)(*(uint *)(unaff_ESI + 0xcd60) >> 7) & 1) != 0) {
      FUN_005bf8c0(0,1);
    }
    FUN_005beae0(s_euro8_006597a4);
    uVar12 = 0;
    iVar17 = *(int *)(unaff_ESI + 0xc890);
    uVar1 = extraout_ECX_01;
    FUN_00437020(0xde,0xdf,0xde);
    uVar15 = 0xd2;
    uVar14 = 0;
    puVar11 = &DAT_00666f70;
    uVar2 = FUN_00436fb0(0x75,0xe);
    uVar13 = FUN_00436fb0(1,1);
    uVar2 = FUN_00436fd0(uVar13,uVar2);
    (**(code **)(iVar17 + 0xc0))(unaff_ESI + 0x325c,uVar2,puVar11,uVar14,uVar15,uVar1,uVar12);
    FUN_005dc840(0xe);
    FUN_005beae0(s_ProMan8_00658928);
    FUN_005c1e10();
  }
  return unaff_ESI;
}


