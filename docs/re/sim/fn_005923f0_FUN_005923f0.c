// FUN_005923f0  entry=005923f0  size=4566 bytes
// callers/callees expanded one level from seeds

/* WARNING: Removing unreachable block (ram,0x005929fd) */
/* WARNING: Removing unreachable block (ram,0x00592a1e) */

undefined1 FUN_005923f0(void)

{
  undefined1 *puVar1;
  void *pvVar2;
  undefined1 uVar3;
  char cVar4;
  int *piVar5;
  undefined4 *puVar6;
  undefined4 uVar7;
  void *extraout_ECX;
  int iVar8;
  void *pvVar9;
  undefined **ppuVar10;
  undefined1 *puVar11;
  undefined4 *puVar12;
  int unaff_retaddr;
  CHAR in_stack_00000020;
  undefined4 in_stack_00000128;
  undefined4 *in_stack_0000012c;
  undefined4 in_stack_00000130;
  void *in_stack_00001f0c;
  undefined4 in_stack_00001f1c;
  LPCSTR pCVar13;
  char *pcVar14;
  void *local_c;
  undefined **local_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  local_8 = (undefined **)&LAB_00620b6a;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_00605f80();
  local_c = extraout_ECX;
  if (*(char *)((int)extraout_ECX + 0x5fac) != '\0') {
    FUN_005a1760();
    FUN_005ec020();
    FUN_005c9210();
    FUN_005c9210();
    FUN_005c9210();
    puVar12 = &DAT_0066f5b4;
    for (iVar8 = 0x100; iVar8 != 0; iVar8 = iVar8 + -1) {
      *puVar12 = 0;
      puVar12 = puVar12 + 1;
    }
    FUN_005db5d0();
    FUN_005db5d0();
    FUN_005a1b30();
    FUN_005c9f60();
    FUN_005a1b30();
    FUN_005c9f60();
    FUN_005a1b30();
    FUN_005c9f60();
    FUN_005a1b30();
    FUN_005c9f60();
    iVar8 = 0;
    puVar12 = (undefined4 *)&stack0x00000134;
    do {
      local_8 = (undefined **)(iVar8 + unaff_retaddr);
      piVar5 = (int *)FUN_005a1ce0();
      *piVar5 = (int)local_8;
      puVar6 = (undefined4 *)FUN_005a1ce0();
      *puVar6 = 0x18;
      lstrcpyA(&stack0x000004fc,&DAT_00664ba0);
      FUN_0059a260();
      FUN_0051fd00();
      uVar7 = FUN_005f69b0();
      *puVar12 = uVar7;
      iVar8 = iVar8 + 0x4c;
      puVar12 = puVar12 + 1;
    } while (iVar8 < 0x130);
    FUN_005c9f60();
    FUN_005bb740();
    FUN_005db5d0();
    iVar8 = 0;
    do {
      local_8 = (undefined **)0x0;
      local_4 = 0;
      FUN_004b7f40();
      FUN_00436fd0();
      FUN_004f7f20();
      iVar8 = iVar8 + 0x4c;
    } while (iVar8 < 0x130);
    FUN_005f70b0();
    FUN_005f2cf0();
    FUN_005f2cf0();
    iVar8 = 0;
    do {
      FUN_005f3410();
      iVar8 = iVar8 + 1;
    } while (iVar8 < 500);
    FUN_005f70b0();
    pvVar9 = local_c;
    FUN_005f2cf0();
    FUN_005f2cf0();
    local_8 = (undefined **)((int)pvVar9 + 0x5e88);
    ppuVar10 = &PTR_s_PARADOS_00663f10;
    do {
      if (**ppuVar10 == '\0') {
        *local_8 = (undefined *)0xffffffff;
      }
      else {
        if (*(int *)((int)pvVar9 + 0x29b4) == 0) {
          uVar7 = 0;
        }
        else {
          uVar7 = *(undefined4 *)(*(int *)((int)pvVar9 + 0x29b0) + 0x120);
        }
        *local_8 = (undefined *)uVar7;
        lstrcpyA(&stack0x000004fc,s_Modelos__00664db8);
        FUN_004c4200();
        FUN_0051fd00();
        lstrcpyA(&stack0x0000018c,&stack0x00000020);
        FUN_004c4200();
        FUN_0051fd00();
        iVar8 = FUN_005ec1d0();
        if (iVar8 == 0) {
          lstrcpyA(&stack0x00000710,s_Modelos__00664db8);
          FUN_004c4200();
          FUN_0051fd00();
          lstrcpyA(&stack0x00000810,&stack0x0000140c);
          FUN_004c4200();
          FUN_0051fd00();
          FUN_005f2d50();
        }
        else {
          lstrcpyA(&stack0x000003fc,s_Modelos__00664db8);
          FUN_004c4200();
          FUN_0051fd00();
          lstrcpyA(&stack0x00000910,&stack0x000002e8);
          FUN_004c4200();
          FUN_0051fd00();
          FUN_005f2d50();
        }
      }
      ppuVar10 = ppuVar10 + 1;
      local_8 = local_8 + 1;
      pvVar9 = local_c;
    } while ((int)ppuVar10 < 0x664034);
    FUN_005f0ee0();
    FUN_005f33a0();
    thunk_FUN_005cb040();
    thunk_FUN_005cb040();
    thunk_FUN_005cb040();
    FUN_005ec0e0();
    FUN_005a1bb0();
  }
  FUN_005ec250();
  FUN_005ec250();
  FUN_005ec020();
  FUN_005ec020();
  lstrcpyA(&stack0x0000150c,s_DatSim_paletas_palarb_00664d4c);
  FUN_0059a260();
  FUN_0051fd00();
  lstrcpyA(&stack0x000004fc,&stack0x00001c0c);
  pCVar13 = &DAT_00664d44;
  iVar8 = lstrlenA(&stack0x000004fc);
  lstrcpyA(&stack0x000004fc + iVar8,pCVar13);
  FUN_0051fd00();
  FUN_005ec020();
  lstrcpyA(&stack0x0000190c,s_DatSim_paletas_pallin_00664d2c);
  FUN_0059a260();
  FUN_0051fd00();
  lstrcpyA(&stack0x0000180c,&stack0x00001a0c);
  FUN_004c4200();
  FUN_0051fd00();
  FUN_005ec020();
  lstrcpyA(&stack0x0000170c,s_DatSim_paletas_pallin_00664d2c);
  FUN_0059a260();
  FUN_0051fd00();
  lstrcpyA(&stack0x0000160c,&stack0x00001d0c);
  FUN_004c4200();
  FUN_0051fd00();
  FUN_005ec020();
  lstrcpyA(&stack0x0000014c,s_DatSim_hierba_raw_00664d08);
  pvVar9 = local_c;
  *(undefined4 *)((int)local_c + 0x468) = in_stack_00001f1c;
  iVar8 = FUN_005ec250();
  *(int *)((int)pvVar9 + 0x1980) = (int)(iVar8 * 5 + (iVar8 * 5 >> 0x1f & 0x7fffU)) >> 0xf;
  ppuVar10 = &PTR_s_ALIENTO_00663c40;
  do {
    ppuVar10 = ppuVar10 + 5;
    FUN_00590c90();
    pvVar9 = local_c;
  } while ((int)ppuVar10 < 0x663f10);
  *(undefined4 *)((int)local_c + 0x1a64) = 0;
  FUN_005ec130();
  FUN_005c9f60();
  if (*(int *)((int)pvVar9 + 0x2550) == 0) {
    FUN_005cb2b0();
  }
  if (*(char *)((int)pvVar9 + 0x5fac) == '\0') {
    local_8 = *(undefined ***)((int)pvVar9 + 0x1980);
    lstrcpyA(&stack0x000003fc,s_Dat_simul_00664cd4);
    FUN_0059a260();
    FUN_0051fd00();
    lstrcpyA(&stack0x0000018c,&stack0x00000020);
    pCVar13 = &DAT_00664ccc;
    iVar8 = lstrlenA(&stack0x0000018c);
    lstrcpyA(&stack0x0000018c + iVar8,pCVar13);
    FUN_0051fd00();
    FUN_005ec020();
    puVar12 = (undefined4 *)0x18;
    puVar6 = (undefined4 *)((int)pvVar9 + 0x1e68);
    for (iVar8 = 0x100; iVar8 != 0; iVar8 = iVar8 + -1) {
      *puVar6 = *puVar12;
      puVar12 = puVar12 + 1;
      puVar6 = puVar6 + 1;
    }
  }
  else {
    in_stack_00000020 = '\0';
    in_stack_00000128 = 0;
    in_stack_0000012c = (undefined4 *)0x0;
    in_stack_00000130 = 0;
    FUN_005ec020();
    puVar12 = (undefined4 *)((int)in_stack_0000012c + 0x18);
    puVar6 = (undefined4 *)((int)pvVar9 + 0x1e68);
    for (iVar8 = 0x100; iVar8 != 0; iVar8 = iVar8 + -1) {
      *puVar6 = *puVar12;
      puVar12 = puVar12 + 1;
      puVar6 = puVar6 + 1;
    }
  }
  FUN_005ec0e0();
  puVar12 = (undefined4 *)((int)local_c + 0x1a68);
  local_8 = (undefined **)puVar12;
  puVar6 = (undefined4 *)FUN_005c1ba0();
  for (iVar8 = 0x100; iVar8 != 0; iVar8 = iVar8 + -1) {
    *puVar12 = *puVar6;
    puVar6 = puVar6 + 1;
    puVar12 = puVar12 + 1;
  }
  puVar1 = (undefined1 *)((int)local_c + 0x2368);
  iVar8 = -0x2368 - (int)local_c;
  puVar11 = puVar1;
  do {
    uVar3 = FUN_005db6b0();
    puVar11[-0x100] = uVar3;
    uVar3 = FUN_005db6b0();
    pvVar9 = local_c;
    *puVar11 = uVar3;
    puVar11 = puVar11 + 1;
  } while ((int)(puVar11 + iVar8) < 0x100);
  piVar5 = (int *)((int)local_c + 0x1a54);
  *puVar1 = 0;
  *(undefined1 *)((int)local_c + 0x2268) = 0;
  *(undefined4 *)((int)local_c + 0x1a60) = 7;
  FUN_005bbf10();
  pvVar2 = local_c;
  iVar8 = *piVar5;
  *(undefined4 *)((int)pvVar9 + 0x1a58) = 0x7ff;
  iVar8 = iVar8 + 0xff;
  *(int *)((int)pvVar9 + 0x1a5c) = ((int)(iVar8 + (iVar8 >> 0x1f & 0xffU)) >> 8) << 8;
  puVar12 = (undefined4 *)0x0;
  puVar6 = (undefined4 *)(*(int *)((int)pvVar9 + 0x1a5c) + 0x400);
  for (iVar8 = 0x40; iVar8 != 0; iVar8 = iVar8 + -1) {
    *puVar6 = *puVar12;
    puVar12 = puVar12 + 1;
    puVar6 = puVar6 + 1;
  }
  puVar12 = (undefined4 *)0x0;
  puVar6 = (undefined4 *)(*(int *)((int)local_c + 0x1a5c) + 0x500);
  for (iVar8 = 0x40; iVar8 != 0; iVar8 = iVar8 + -1) {
    *puVar6 = *puVar12;
    puVar12 = puVar12 + 1;
    puVar6 = puVar6 + 1;
  }
  puVar12 = (undefined4 *)0x0;
  puVar6 = (undefined4 *)(*(int *)((int)local_c + 0x1a5c) + 0x600);
  for (iVar8 = 0x40; iVar8 != 0; iVar8 = iVar8 + -1) {
    *puVar6 = *puVar12;
    puVar12 = puVar12 + 1;
    puVar6 = puVar6 + 1;
  }
  puVar12 = (undefined4 *)0x0;
  puVar6 = *(undefined4 **)((int)local_c + 0x1a5c);
  for (iVar8 = 0x40; iVar8 != 0; iVar8 = iVar8 + -1) {
    *puVar6 = *puVar12;
    puVar12 = puVar12 + 1;
    puVar6 = puVar6 + 1;
  }
  puVar12 = (undefined4 *)0x0;
  puVar6 = (undefined4 *)(*(int *)((int)local_c + 0x1a5c) + 0x200);
  for (iVar8 = 0x40; iVar8 != 0; iVar8 = iVar8 + -1) {
    *puVar6 = *puVar12;
    puVar12 = puVar12 + 1;
    puVar6 = puVar6 + 1;
  }
  piVar5 = (int *)((int)local_c + 0x1a44);
  *(undefined4 *)((int)local_c + 0x1a50) = 4;
  FUN_005bbf10();
  iVar8 = *piVar5;
  *(undefined4 *)((int)pvVar2 + 0x1a48) = 0x4ffff;
  iVar8 = iVar8 + 0xffff;
  *(int *)((int)pvVar2 + 0x1a4c) = ((int)(iVar8 + (iVar8 >> 0x1f & 0xffffU)) >> 0x10) << 0x10;
  switch(DAT_00674e7c) {
  case 2:
    pcVar14 = s_DatSim_hierprem_raw_00664cb8;
    if (DAT_00674e78 != 1) {
      pcVar14 = s_DatSim_hieprees_raw_00664ca4;
    }
    break;
  default:
    goto switchD_0059301c_caseD_3;
  case 4:
    pcVar14 = s_DatSim_hiercal_raw_00664c90;
    if (DAT_00674e78 != 2) {
      pcVar14 = s_DatSim_hiercale_raw_00664c7c;
    }
    break;
  case 8:
    pcVar14 = s_DatSim_hiebarsa_raw_00664c68;
    break;
  case 0x10:
    pcVar14 = s_DatSim_hierarg_raw_00664c54;
  }
  lstrcpyA(&stack0x0000014c,pcVar14);
switchD_0059301c_caseD_3:
  in_stack_00000128 = 0;
  in_stack_0000012c = (undefined4 *)0x0;
  in_stack_00000130 = 0;
  in_stack_00000020 = '\0';
  FUN_005ec020();
  puVar12 = in_stack_0000012c;
  puVar6 = (undefined4 *)(*(int *)((int)local_c + 0x1a4c) + 0x10000);
  for (iVar8 = 0x4000; iVar8 != 0; iVar8 = iVar8 + -1) {
    *puVar6 = *puVar12;
    puVar12 = puVar12 + 1;
    puVar6 = puVar6 + 1;
  }
  FUN_005ec0e0();
  in_stack_00000020 = '\0';
  in_stack_00000128 = 0;
  in_stack_0000012c = (undefined4 *)0x0;
  in_stack_00000130 = 0;
  FUN_005ec020();
  puVar12 = in_stack_0000012c;
  puVar6 = (undefined4 *)(*(int *)((int)local_c + 0x1a4c) + 0x20000);
  for (iVar8 = 0x4000; iVar8 != 0; iVar8 = iVar8 + -1) {
    *puVar6 = *puVar12;
    puVar12 = puVar12 + 1;
    puVar6 = puVar6 + 1;
  }
  FUN_005ec0e0();
  in_stack_00000020 = '\0';
  in_stack_00000128 = 0;
  in_stack_0000012c = (undefined4 *)0x0;
  in_stack_00000130 = 0;
  FUN_005ec020();
  puVar12 = in_stack_0000012c;
  puVar6 = (undefined4 *)(*(int *)((int)local_c + 0x1a4c) + 0x30000);
  for (iVar8 = 0x4000; iVar8 != 0; iVar8 = iVar8 + -1) {
    *puVar6 = *puVar12;
    puVar12 = puVar12 + 1;
    puVar6 = puVar6 + 1;
  }
  FUN_005ec0e0();
  FUN_005c9f60();
  FUN_005c9f60();
  local_8 = &PTR_s_coreloj_00664038;
  do {
    pCVar13 = *local_8;
    lstrcpyA(&stack0x0000110c,s_Datsim__00664bf0);
    iVar8 = lstrlenA(&stack0x0000110c);
    lstrcpyA(&stack0x0000110c + iVar8,pCVar13);
    lstrcpyA(&stack0x0000130c,&stack0x0000110c);
    puVar12 = (undefined4 *)&stack0x0000110d;
    puVar6 = (undefined4 *)&stack0x0000130d;
    for (iVar8 = 0x3f; iVar8 != 0; iVar8 = iVar8 + -1) {
      *puVar6 = *puVar12;
      puVar12 = puVar12 + 1;
      puVar6 = puVar6 + 1;
    }
    *(undefined2 *)puVar6 = *(undefined2 *)puVar12;
    *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar12 + 2);
    lstrcpyA(&stack0x00000810,&stack0x0000130c);
    pCVar13 = &DAT_00664be8;
    iVar8 = lstrlenA(&stack0x00000810);
    lstrcpyA(&stack0x00000810 + iVar8,pCVar13);
    lstrcpyA(&stack0x0000140c,&stack0x00000810);
    puVar12 = (undefined4 *)&stack0x00000811;
    puVar6 = (undefined4 *)&stack0x0000140d;
    for (iVar8 = 0x3f; iVar8 != 0; iVar8 = iVar8 + -1) {
      *puVar6 = *puVar12;
      puVar12 = puVar12 + 1;
      puVar6 = puVar6 + 1;
    }
    *(undefined2 *)puVar6 = *(undefined2 *)puVar12;
    *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar12 + 2);
    cVar4 = FUN_005d35d0();
    if (cVar4 == '\0') {
      pCVar13 = *local_8;
      lstrcpyA(&stack0x00000710,s_FLCs__00664be0);
      iVar8 = lstrlenA(&stack0x00000710);
      lstrcpyA(&stack0x00000710 + iVar8,pCVar13);
      lstrcpyA(&stack0x0000120c,&stack0x00000710);
      puVar12 = (undefined4 *)&stack0x00000711;
      puVar6 = (undefined4 *)&stack0x0000120d;
      for (iVar8 = 0x3f; iVar8 != 0; iVar8 = iVar8 + -1) {
        *puVar6 = *puVar12;
        puVar12 = puVar12 + 1;
        puVar6 = puVar6 + 1;
      }
      *(undefined2 *)puVar6 = *(undefined2 *)puVar12;
      *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar12 + 2);
      lstrcpyA(&stack0x00000910,&stack0x0000120c);
      pCVar13 = &DAT_00664bd8;
      iVar8 = lstrlenA(&stack0x00000910);
      lstrcpyA(&stack0x00000910 + iVar8,pCVar13);
      lstrcpyA(&stack0x000002e8,&stack0x00000910);
      puVar12 = (undefined4 *)&stack0x00000911;
      puVar6 = (undefined4 *)&stack0x000002e9;
      for (iVar8 = 0x3f; iVar8 != 0; iVar8 = iVar8 + -1) {
        *puVar6 = *puVar12;
        puVar12 = puVar12 + 1;
        puVar6 = puVar6 + 1;
      }
      *(undefined2 *)puVar6 = *(undefined2 *)puVar12;
      *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar12 + 2);
      FUN_005d35d0();
      pCVar13 = *local_8;
      lstrcpyA(&stack0x000003fc,s_Datsim__00664bf0);
      iVar8 = lstrlenA(&stack0x000003fc);
      lstrcpyA(&stack0x000003fc + iVar8,pCVar13);
      lstrcpyA(&stack0x00000c38,&stack0x000003fc);
      puVar12 = (undefined4 *)&stack0x000003fd;
      puVar6 = (undefined4 *)&stack0x00000c39;
      for (iVar8 = 0x3f; iVar8 != 0; iVar8 = iVar8 + -1) {
        *puVar6 = *puVar12;
        puVar12 = puVar12 + 1;
        puVar6 = puVar6 + 1;
      }
      *(undefined2 *)puVar6 = *(undefined2 *)puVar12;
      *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar12 + 2);
      lstrcpyA(&stack0x0000018c,&stack0x00000c38);
      pCVar13 = &DAT_00664be8;
      iVar8 = lstrlenA(&stack0x0000018c);
      lstrcpyA(&stack0x0000018c + iVar8,pCVar13);
      lstrcpyA(&stack0x00000020,&stack0x0000018c);
      puVar12 = (undefined4 *)&stack0x0000018d;
      puVar6 = (undefined4 *)&stack0x00000021;
      for (iVar8 = 0x3f; iVar8 != 0; iVar8 = iVar8 + -1) {
        *puVar6 = *puVar12;
        puVar12 = puVar12 + 1;
        puVar6 = puVar6 + 1;
      }
      *(undefined2 *)puVar6 = *(undefined2 *)puVar12;
      *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar12 + 2);
      FUN_005d40b0();
    }
    local_8 = local_8 + 1;
  } while ((int)local_8 < 0x66405c);
  cVar4 = FUN_005d35d0();
  if (cVar4 == '\0') {
    FUN_005d35d0();
    if (*PTR_s_porpara_flc_00664f48 != '\0') {
      local_8 = &PTR_s_porpara_flc_00664f48;
      pcVar14 = PTR_s_porpara_flc_00664f48;
      do {
        lstrcpyA(&stack0x0000018c,s_FLCs__00664be0);
        iVar8 = lstrlenA(&stack0x0000018c);
        lstrcpyA(&stack0x0000018c + iVar8,pcVar14);
        lstrcpyA(&stack0x00000020,&stack0x0000018c);
        puVar12 = (undefined4 *)&stack0x0000018d;
        puVar6 = (undefined4 *)&stack0x00000021;
        for (iVar8 = 0x3f; iVar8 != 0; iVar8 = iVar8 + -1) {
          *puVar6 = *puVar12;
          puVar12 = puVar12 + 1;
          puVar6 = puVar6 + 1;
        }
        *(undefined2 *)puVar6 = *(undefined2 *)puVar12;
        *(undefined1 *)((int)puVar6 + 2) = *(undefined1 *)((int)puVar12 + 2);
        FUN_005d35d0();
        local_8 = local_8 + 1;
        pcVar14 = *local_8;
      } while (*pcVar14 != '\0');
    }
    FUN_005d40b0();
  }
  iVar8 = 0;
  do {
    FUN_005b63e0();
    iVar8 = iVar8 + 0x7a0;
  } while (iVar8 < 0xf40);
  FUN_005d8dd0();
  DAT_00674258 = FUN_005f69b0();
  uVar3 = FUN_00593600();
  FUN_005ec0e0();
  FUN_005ec0e0();
  FUN_005ec0e0();
  FUN_005ec0e0();
  FUN_005ec0e0();
  ExceptionList = in_stack_00001f0c;
  return uVar3;
}


