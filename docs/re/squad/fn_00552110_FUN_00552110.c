// FUN_00552110  entry=00552110  size=1233 bytes

/* WARNING: Type propagation algorithm not settling */

undefined4 __thiscall FUN_00552110(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  int iVar2;
  undefined4 uVar3;
  undefined *puVar4;
  int iVar5;
  undefined4 extraout_ECX;
  int iVar6;
  int *piVar7;
  int *piVar8;
  undefined1 *puVar9;
  undefined4 uVar10;
  int iVar11;
  undefined4 uVar12;
  undefined **ppuVar13;
  int iVar14;
  char *pcVar15;
  undefined *puVar16;
  undefined4 uVar17;
  int iVar18;
  undefined4 uVar19;
  int iStack_a4;
  undefined4 uStack_a0;
  int iStack_9c;
  char *pcStack_98;
  CRect aCStack_80 [4];
  undefined1 auStack_7c [24];
  undefined4 uStack_64;
  undefined4 uStack_60;
  undefined4 uStack_5c;
  undefined4 uStack_58;
  int iStack_50;
  int iStack_4c;
  
  pcStack_98 = (char *)param_2;
  iStack_9c = 0x55213a;
  iStack_50 = param_1;
  iStack_4c = FUN_004fa840();
  uStack_a0 = 0;
  if (iStack_4c != 0) {
    pcStack_98 = s_ProMan12_006567d4;
    iStack_9c = 0x552156;
    FUN_005beae0();
    pcStack_98 = (char *)0xffffffff;
    iStack_9c = 0;
    *(char **)(param_1 + 0xccc) = s_INFOFUT_if5mapla_htm_0065f0d4;
    FUN_005c9f60();
    pcStack_98 = (char *)0xffffffff;
    iStack_9c = 0;
    FUN_005c9f60();
    pcStack_98 = (char *)0xffffffff;
    iStack_9c = 0;
    FUN_005c9f60();
    pcStack_98 = (char *)0xffffffff;
    iStack_9c = 0;
    FUN_005c9f60();
    pcStack_98 = (char *)&uStack_64;
    uStack_64 = 8;
    uStack_60 = 0x48;
    uStack_5c = 0x204;
    uStack_58 = 0x1d5;
    iStack_9c = param_1;
    FUN_004f50c0();
    pcStack_98 = s_ProMan10_006551e0;
    iStack_9c = 0x5521eb;
    FUN_005beae0();
    *(undefined4 *)(param_1 + 0x197c) = 0;
    pcStack_98 = (char *)0xc8a0a0;
    iVar18 = *(int *)(param_1 + 0x26a0);
    FUN_00437020();
    uStack_a0 = 900;
    iStack_a4 = 0;
    CRect::CRect((CRect *)&uStack_64,0x213,0x1b8,0x271,0x1d1);
    (**(code **)(iVar18 + 0xc0))();
    iVar18 = *(int *)(param_1 + 0x2ab8);
    FUN_00437020(0xff,0xdf,0);
    uVar19 = 0x3ad;
    uVar17 = 0;
    pcVar15 = s_YOUTH_TEAM_0065d428;
    uVar3 = CRect::CRect(aCStack_80,0x20b,0x168,0x27b,0x181);
    (**(code **)(iVar18 + 0xc0))(param_1,uVar3,pcVar15,uVar17,uVar19);
    FUN_005c06d0(s_recursos_iconos_plantilla_juveni_0065f0ac,0,0,0x32,0);
    uVar12 = 0;
    iVar18 = *(int *)(param_1 + 0x484);
    uVar3 = extraout_ECX;
    FUN_00436270(0xffffff);
    uVar10 = 0;
    uVar19 = 0x808;
    pcVar15 = s_SQUAD_MANAGEMENT_0065f098;
    uVar17 = CRect::CRect((CRect *)&iStack_9c,0x96,0x10,0x1bf,0x2b);
    (**(code **)(iVar18 + 0xc0))(param_1,uVar17,pcVar15,uVar19,uVar10,uVar3,uVar12);
    FUN_005beae0(s_ProMan14_00656830);
    *(undefined1 *)(param_1 + 0x4e9) = 0x20;
    iVar18 = 0;
    iVar11 = 0;
    ppuVar13 = (undefined **)&DAT_00634e28;
    piVar7 = (int *)(param_1 + 0x3cac);
    do {
      puVar4 = (undefined *)FUN_005884f0(iVar11);
      puVar1 = *ppuVar13;
      iVar5 = *piVar7;
      FUN_00437020(0x78,0x8c,0xa0);
      iVar6 = iVar11 + 0x96;
      uVar19 = 0;
      puVar9 = &DAT_00666f70;
      uVar3 = FUN_00436fb0(0x10,(int)puVar1 * 0x10 + -2);
      uVar17 = FUN_00436fb0(0x1dd,1);
      uVar17 = FUN_00435e60(auStack_7c,uVar17);
      uVar3 = FUN_00436fd0(uVar17,uVar3);
      (**(code **)(iVar5 + 0xc0))(param_1 + 0x1928,uVar3,puVar9,uVar19,iVar6);
      FUN_005dbe70(puVar4,puVar1,1,puVar1);
      FUN_005c0d50(param_1 + 0x3c60,0,0,0x32,0);
      FUN_005c0d50(param_1 + 0x3c14,3,0,0x32,0xffffffff);
      FUN_005c0d50(param_1 + 0x3bc8,0,0,0x32,0);
      FUN_005c0d50(param_1 + 0x3b7c,3,0,0x32,0xffffffff);
      puVar16 = (undefined *)0x0;
      if (puVar1 != (undefined *)0x0) {
        iVar6 = 0;
        iVar5 = iVar18 + 100;
        piVar8 = (int *)(param_1 + 0xa16c + iVar18 * 0x418);
        iVar18 = iVar18 + (int)puVar1;
        do {
          iVar14 = iVar5;
          if (puVar16 < puVar4) {
            iVar2 = *piVar8;
            FUN_00436270(0xffffffff);
            uVar19 = 0x200000;
            puVar9 = &DAT_00666f70;
            iVar14 = iVar5;
            uVar3 = FUN_00436fb0(0x1d2,0x10);
            uVar17 = FUN_00436fb0(0,iVar6);
            uVar17 = FUN_00435e60(&stack0xffffff48,uVar17);
            uVar3 = FUN_00436fd0(uVar17,uVar3);
            (**(code **)(iVar2 + 0xc0))(0x1928,uVar3,puVar9,uVar19,iVar5);
            FUN_005beae0(s_ProMan8_00658928);
            iVar5 = FUN_00588580(iVar11,puVar16);
            piVar8[0x15] = iVar5;
            param_1 = iStack_a4;
          }
          iVar5 = iVar14 + 1;
          piVar8 = piVar8 + 0x106;
          puVar16 = puVar16 + 1;
          iVar6 = iVar6 + 0x10;
        } while (puVar16 < puVar1);
      }
      iVar5 = iStack_4c;
      iVar11 = iVar11 + 1;
      piVar7 = piVar7 + 0x64c;
      ppuVar13 = ppuVar13 + 1;
    } while (ppuVar13 < &PTR_LOOP_00634e38);
    FUN_004f4860(param_1,*(undefined4 *)(iStack_4c + 0x10),0);
    FUN_004f4b00(param_1,0x1bf,0);
    FUN_00465d90(param_1,*(undefined4 *)(iVar5 + 0x10));
  }
  return uStack_a0;
}


