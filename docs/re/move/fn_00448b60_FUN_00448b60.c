// FUN_00448b60  entry=00448b60  size=2180 bytes

void FUN_00448b60(int param_1)

{
  int *piVar1;
  ushort uVar2;
  int iVar3;
  int iVar4;
  int *extraout_ECX;
  int iVar5;
  int iVar6;
  bool bVar7;
  undefined1 local_fbc [3904];
  int local_7c;
  int local_78;
  undefined4 uStack_38;
  undefined1 *puStack_34;
  undefined1 *puStack_30;
  int iStack_2c;
  code *pcStack_28;
  code *pcStack_24;
  void *local_10;
  undefined1 *puStack_c;
  int local_8;
  
  local_8 = 0xffffffff;
  puStack_c = &LAB_00609c2e;
  local_10 = ExceptionList;
  ExceptionList = &local_10;
  FUN_00605f80();
  local_8 = 0;
  if ((DAT_0066b200 != 0) && (extraout_ECX[0x10] != 0)) {
    ExceptionList = local_10;
    return;
  }
  if (*extraout_ECX == 0) {
    *extraout_ECX = DAT_0066afd4;
  }
  for (iVar5 = 0;
      ((&DAT_00653018)[iVar5] != 0 && ((short)extraout_ECX[0x11] != (&DAT_00653018)[iVar5]));
      iVar5 = iVar5 + 1) {
  }
  extraout_ECX[0x2d] = 0;
  if ((DAT_0066b18f == '\f') || ((DAT_0066b18f == '\x01' || (DAT_0066b18f == '\x02')))) {
    if ((&DAT_00653018)[iVar5] == 0) {
      if (((short)extraout_ECX[0x11] != 0x41) && ((short)extraout_ECX[0x11] != 0x6b))
      goto LAB_00448c56;
      pcStack_24 = (code *)0x448c22;
      iVar5 = rand();
      iVar5 = (int)(iVar5 * 0x65 + (iVar5 * 0x65 >> 0x1f & 0x7fffU)) >> 0xf;
      bVar7 = SBORROW4(iVar5,0x14);
      iVar5 = iVar5 + -0x14;
    }
    else {
      pcStack_24 = (code *)0x448bee;
      iVar5 = rand();
      iVar5 = (int)(iVar5 * 0x65 + (iVar5 * 0x65 >> 0x1f & 0x7fffU)) >> 0xf;
      bVar7 = SBORROW4(iVar5,5);
      iVar5 = iVar5 + -5;
    }
    extraout_ECX[0x2d] = (bVar7 == iVar5 < 0) - 1 & 100;
  }
LAB_00448c56:
  if ((((DAT_0066b18f == '\v') || (DAT_0066b18f == '\f')) || (DAT_0066b18f == '\x01')) ||
     (DAT_0066b18f == '\x02')) {
    pcStack_24 = (code *)0x448c70;
    iVar5 = rand();
    extraout_ECX[0x2e] =
         (4 < (int)(iVar5 * 0x65 + (iVar5 * 0x65 >> 0x1f & 0x7fffU)) >> 0xf) - 1 & 100;
  }
  else {
    extraout_ECX[0x2e] = 0;
  }
  for (iVar5 = 0;
      ((&DAT_00653060)[iVar5] != 0 && ((short)extraout_ECX[0x11] != (&DAT_00653060)[iVar5]));
      iVar5 = iVar5 + 1) {
  }
  if ((&DAT_00653060)[iVar5] != 0) {
    if (((DAT_0066b18f == '\v') || (DAT_0066b18f == '\f')) ||
       ((DAT_0066b18f == '\x01' || (DAT_0066b18f == '\x02')))) {
      pcStack_24 = (code *)0x448cee;
      iVar5 = rand();
      iVar5 = (int)(iVar5 * 0x65 + (iVar5 * 0x65 >> 0x1f & 0x7fffU)) >> 0xf;
      bVar7 = SBORROW4(iVar5,0x23);
      iVar5 = iVar5 + -0x23;
    }
    else {
      pcStack_24 = (code *)0x448cd0;
      iVar5 = rand();
      iVar5 = (int)(iVar5 * 0x65 + (iVar5 * 0x65 >> 0x1f & 0x7fffU)) >> 0xf;
      bVar7 = SBORROW4(iVar5,0xf);
      iVar5 = iVar5 + -0xf;
    }
    extraout_ECX[0x2e] = (bVar7 == iVar5 < 0) - 1 & 100;
  }
  for (iVar5 = 0;
      ((&DAT_006530a8)[iVar5] != 0 && ((short)extraout_ECX[0x11] != (&DAT_006530a8)[iVar5]));
      iVar5 = iVar5 + 1) {
  }
  if ((&DAT_006530a8)[iVar5] != 0) {
    if ((((DAT_0066b18f == '\v') || (DAT_0066b18f == '\f')) || (DAT_0066b18f == '\x01')) ||
       (DAT_0066b18f == '\x02')) {
      pcStack_24 = (code *)0x448d6c;
      iVar5 = rand();
      iVar5 = (int)(iVar5 * 0x65 + (iVar5 * 0x65 >> 0x1f & 0x7fffU)) >> 0xf;
      bVar7 = SBORROW4(iVar5,0xf);
      iVar5 = iVar5 + -0xf;
    }
    else {
      pcStack_24 = (code *)0x448d4e;
      iVar5 = rand();
      iVar5 = (int)(iVar5 * 0x65 + (iVar5 * 0x65 >> 0x1f & 0x7fffU)) >> 0xf;
      bVar7 = SBORROW4(iVar5,10);
      iVar5 = iVar5 + -10;
    }
    extraout_ECX[0x2e] = (bVar7 == iVar5 < 0) - 1 & 100;
  }
  pcStack_24 = (code *)(uint)*(ushort *)(extraout_ECX + 0xe);
  pcStack_28 = (code *)0x448daa;
  FUN_00585ee0();
  pcStack_24 = (code *)0x448db1;
  FUN_005793d0();
  pcStack_24 = (code *)(uint)*(ushort *)((int)extraout_ECX + 0x3a);
  pcStack_28 = (code *)0x448dc4;
  FUN_00585ee0();
  pcStack_24 = (code *)0x448dcb;
  iVar5 = FUN_005793d0();
  if (*(int *)(iVar5 + 0x5c) == 0xffff) {
    pcStack_24 = (code *)0x448ddd;
    FUN_0057a980();
  }
  else {
    pcStack_24 = (code *)0x448de8;
    FUN_0057a980();
  }
  pcStack_24 = (code *)0x448def;
  FUN_0057a980();
  DAT_0066b200 = 0;
  *(undefined1 *)(extraout_ECX + 0xf) = 0;
  *(undefined1 *)((int)extraout_ECX + 0x3d) = 0;
  *(undefined1 *)(extraout_ECX + 0x13) = 0;
  *(undefined1 *)((int)extraout_ECX + 0x4d) = 0;
  *(undefined1 *)(extraout_ECX + 0x15) = 0;
  *(undefined1 *)((int)extraout_ECX + 0x55) = 0;
  extraout_ECX[0x10] = 0;
  extraout_ECX[0x12] = 0;
  extraout_ECX[0x14] = 0;
  do {
    iVar5 = extraout_ECX[0x26];
    extraout_ECX[0x26] = iVar5 + -1;
  } while (iVar5 != 0);
  pcStack_24 = (code *)extraout_ECX[0x25];
  if (pcStack_24 != (code *)0x0) {
    pcStack_28 = (code *)0x448e3b;
    FUN_005bbed0();
    extraout_ECX[0x25] = 0;
  }
  extraout_ECX[0x26] = 0;
  pcStack_24 = (code *)0x448e51;
  FUN_00449960();
  do {
    iVar5 = extraout_ECX[0x28];
    extraout_ECX[0x28] = iVar5 + -1;
  } while (iVar5 != 0);
  pcStack_24 = (code *)extraout_ECX[0x27];
  if (pcStack_24 != (code *)0x0) {
    pcStack_28 = (code *)0x448e74;
    FUN_005bbed0();
    extraout_ECX[0x27] = 0;
  }
  extraout_ECX[0x28] = 0;
  pcStack_24 = (code *)0x448e8e;
  FUN_00591880();
  pcStack_24 = FUN_0044bbd0;
  pcStack_28 = FUN_00449400;
  iStack_2c = 2;
  puStack_34 = local_fbc;
  puStack_30 = (undefined1 *)0x7a0;
  uStack_38 = 0x448ec7;
  FUN_00605ee0();
  pcStack_24 = (code *)0x0;
  local_8._0_1_ = 1;
  pcStack_28 = (code *)0x448ed4;
  FUN_0044b940();
  local_8._0_1_ = 2;
  pcStack_24 = (code *)0x448ee0;
  FUN_0044bdc0();
  pcStack_24 = (code *)extraout_ECX[5];
  pcStack_28 = (code *)extraout_ECX[4];
  iStack_2c = extraout_ECX[3];
  puStack_30 = (undefined1 *)extraout_ECX[2];
  local_8._0_1_ = 3;
  puStack_34 = (undefined1 *)0x448f0d;
  FUN_00449bd0();
  pcStack_24 = (code *)0x448f18;
  FUN_0044ee70();
  extraout_ECX[0x10] = 1;
  pcStack_24 = (code *)0x448f26;
  FUN_0044a370();
  pcStack_24 = (code *)(uint)*(ushort *)(extraout_ECX + 0xe);
  pcStack_28 = (code *)0x448f37;
  FUN_00585ee0();
  pcStack_24 = (code *)0x448f3e;
  iVar5 = FUN_005793d0();
  pcStack_24 = (code *)(uint)*(ushort *)((int)extraout_ECX + 0x3a);
  pcStack_28 = (code *)0x448f54;
  FUN_00585ee0();
  pcStack_24 = (code *)0x448f5b;
  iVar3 = FUN_005793d0();
  if (param_1 != 0) {
    for (iVar6 = 0; iVar6 < extraout_ECX[0x28]; iVar6 = iVar6 + 1) {
      uVar2 = *(ushort *)(extraout_ECX[0x27] + 0x44 + iVar6 * 0x48);
      piVar1 = (int *)(extraout_ECX[0x27] + iVar6 * 0x48);
      if (uVar2 < DAT_0066c150) {
        iVar4 = *(int *)(DAT_0066c158 + (uint)uVar2 * 4);
      }
      else {
        iVar4 = 0;
      }
      if (uVar2 == *(ushort *)(extraout_ECX + 0x2b)) {
        piVar1[3] = 1;
      }
      *(int *)(iVar4 + 0x24) = *(int *)(iVar4 + 0x24) + *piVar1;
      *(int *)(iVar4 + 0x28) = *(int *)(iVar4 + 0x28) + piVar1[1];
      *(int *)(iVar4 + 0x2c) = *(int *)(iVar4 + 0x2c) + piVar1[2];
      *(int *)(iVar4 + 0x30) = *(int *)(iVar4 + 0x30) + piVar1[3];
      *(int *)(iVar4 + 0x34) = *(int *)(iVar4 + 0x34) + piVar1[4];
      *(int *)(iVar4 + 0x38) = *(int *)(iVar4 + 0x38) + piVar1[5];
      *(int *)(iVar4 + 0x3c) = *(int *)(iVar4 + 0x3c) + piVar1[6];
      *(int *)(iVar4 + 0x40) = *(int *)(iVar4 + 0x40) + piVar1[7];
      *(int *)(iVar4 + 0x44) = *(int *)(iVar4 + 0x44) + piVar1[8];
      *(int *)(iVar4 + 0x48) = *(int *)(iVar4 + 0x48) + piVar1[9];
      *(int *)(iVar4 + 0x4c) = *(int *)(iVar4 + 0x4c) + piVar1[10];
      *(int *)(iVar4 + 0x50) = *(int *)(iVar4 + 0x50) + piVar1[0xb];
      *(int *)(iVar4 + 0x54) = *(int *)(iVar4 + 0x54) + piVar1[0xc];
      *(int *)(iVar4 + 0x58) = *(int *)(iVar4 + 0x58) + piVar1[0xd];
      *(int *)(iVar4 + 0x5c) = *(int *)(iVar4 + 0x5c) + piVar1[0xe];
      *(int *)(iVar4 + 0x60) = *(int *)(iVar4 + 0x60) + piVar1[0xf];
      *(int *)(iVar4 + 100) = *(int *)(iVar4 + 100) + piVar1[0x10];
    }
    for (iVar6 = 0; iVar6 < extraout_ECX[0x2a]; iVar6 = iVar6 + 1) {
      uVar2 = *(ushort *)(extraout_ECX[0x29] + 0x44 + iVar6 * 0x48);
      piVar1 = (int *)(extraout_ECX[0x29] + iVar6 * 0x48);
      if (uVar2 < DAT_0066c150) {
        iVar4 = *(int *)(DAT_0066c158 + (uint)uVar2 * 4);
      }
      else {
        iVar4 = 0;
      }
      if (uVar2 == *(ushort *)(extraout_ECX + 0x2b)) {
        piVar1[3] = 1;
      }
      *(int *)(iVar4 + 0x24) = *(int *)(iVar4 + 0x24) + *piVar1;
      *(int *)(iVar4 + 0x28) = *(int *)(iVar4 + 0x28) + piVar1[1];
      *(int *)(iVar4 + 0x2c) = *(int *)(iVar4 + 0x2c) + piVar1[2];
      *(int *)(iVar4 + 0x30) = *(int *)(iVar4 + 0x30) + piVar1[3];
      *(int *)(iVar4 + 0x34) = *(int *)(iVar4 + 0x34) + piVar1[4];
      *(int *)(iVar4 + 0x38) = *(int *)(iVar4 + 0x38) + piVar1[5];
      *(int *)(iVar4 + 0x3c) = *(int *)(iVar4 + 0x3c) + piVar1[6];
      *(int *)(iVar4 + 0x40) = *(int *)(iVar4 + 0x40) + piVar1[7];
      *(int *)(iVar4 + 0x44) = *(int *)(iVar4 + 0x44) + piVar1[8];
      *(int *)(iVar4 + 0x48) = *(int *)(iVar4 + 0x48) + piVar1[9];
      *(int *)(iVar4 + 0x4c) = *(int *)(iVar4 + 0x4c) + piVar1[10];
      *(int *)(iVar4 + 0x50) = *(int *)(iVar4 + 0x50) + piVar1[0xb];
      *(int *)(iVar4 + 0x54) = *(int *)(iVar4 + 0x54) + piVar1[0xc];
      *(int *)(iVar4 + 0x58) = *(int *)(iVar4 + 0x58) + piVar1[0xd];
      *(int *)(iVar4 + 0x5c) = *(int *)(iVar4 + 0x5c) + piVar1[0xe];
      *(int *)(iVar4 + 0x60) = *(int *)(iVar4 + 0x60) + piVar1[0xf];
      *(int *)(iVar4 + 100) = *(int *)(iVar4 + 100) + piVar1[0x10];
    }
    if ((extraout_ECX[0x16] == 0) || (iVar6 = 0x78, extraout_ECX[0x12] == 0)) {
      iVar6 = 0x5a;
    }
    *(int *)(iVar5 + 0x274) = *(int *)(iVar5 + 0x274) + iVar6;
    *(int *)(iVar3 + 0x274) = *(int *)(iVar3 + 0x274) + iVar6;
  }
  DAT_0066afd0 = extraout_ECX;
  if ((iVar5 != 0) && (iVar3 != 0)) {
    for (iVar5 = 0; iVar5 < extraout_ECX[0x28]; iVar5 = iVar5 + 1) {
      iVar3 = extraout_ECX[0x27] + iVar5 * 0x48;
      if (*(ushort *)(iVar3 + 0x44) < DAT_0066c150) {
        iStack_2c = *(int *)(DAT_0066c158 + (uint)*(ushort *)(iVar3 + 0x44) * 4);
      }
      else {
        iStack_2c = 0;
      }
      pcStack_24 = *(code **)(iVar3 + 0x34);
      pcStack_28 = *(code **)(iVar3 + 0x30);
      puStack_30 = (undefined1 *)0x44921f;
      (**(code **)(*DAT_0066b1e0 + 0x120))();
    }
    for (iVar5 = 0; iVar5 < extraout_ECX[0x2a]; iVar5 = iVar5 + 1) {
      iVar3 = extraout_ECX[0x29] + iVar5 * 0x48;
      if (*(ushort *)(iVar3 + 0x44) < DAT_0066c150) {
        iStack_2c = *(int *)(DAT_0066c158 + (uint)*(ushort *)(iVar3 + 0x44) * 4);
      }
      else {
        iStack_2c = 0;
      }
      pcStack_24 = *(code **)(iVar3 + 0x34);
      pcStack_28 = *(code **)(iVar3 + 0x30);
      puStack_30 = (undefined1 *)0x449272;
      (**(code **)(*DAT_0066b1e0 + 0x120))();
    }
    pcStack_24 = (code *)0x44927d;
    FUN_0057af10();
    pcStack_24 = (code *)0x449285;
    FUN_0057af10();
    do {
      iVar5 = extraout_ECX[0x26];
      extraout_ECX[0x26] = iVar5 + -1;
    } while (iVar5 != 0);
    pcStack_24 = (code *)extraout_ECX[0x25];
    if (pcStack_24 != (code *)0x0) {
      pcStack_28 = (code *)0x4492aa;
      FUN_005bbed0();
      extraout_ECX[0x25] = 0;
    }
    extraout_ECX[0x26] = 0;
    do {
      iVar5 = extraout_ECX[0x28];
      extraout_ECX[0x28] = iVar5 + -1;
    } while (iVar5 != 0);
    pcStack_24 = (code *)extraout_ECX[0x27];
    if (pcStack_24 != (code *)0x0) {
      pcStack_28 = (code *)0x4492dc;
      FUN_005bbed0();
      extraout_ECX[0x27] = 0;
    }
    extraout_ECX[0x28] = 0;
    do {
      iVar5 = extraout_ECX[0x2a];
      extraout_ECX[0x2a] = iVar5 + -1;
    } while (iVar5 != 0);
    pcStack_24 = (code *)extraout_ECX[0x29];
    if (pcStack_24 != (code *)0x0) {
      pcStack_28 = (code *)0x44930e;
      FUN_005bbed0();
      extraout_ECX[0x29] = 0;
    }
    extraout_ECX[0x2a] = 0;
    DAT_0066afd4 = 0;
    local_8._0_1_ = 5;
    do {
      bVar7 = local_78 != 0;
      local_78 = local_78 + -1;
    } while (bVar7);
    if (local_7c != 0) {
      pcStack_24 = (code *)local_7c;
      pcStack_28 = (code *)0x449343;
      FUN_005bbed0();
      local_7c = 0;
    }
    pcStack_24 = FUN_0044bbd0;
    pcStack_28 = (code *)0x2;
    puStack_30 = local_fbc;
    iStack_2c = 0x7a0;
    local_78 = 0;
    local_8 = (uint)local_8._1_3_ << 8;
    puStack_34 = (undefined1 *)0x449367;
    FUN_00605da0();
    ExceptionList = local_10;
    return;
  }
  local_8._0_1_ = 4;
  do {
    bVar7 = local_78 != 0;
    local_78 = local_78 + -1;
  } while (bVar7);
  if (local_7c != 0) {
    pcStack_24 = (code *)local_7c;
    pcStack_28 = (code *)0x44939a;
    FUN_005bbed0();
    local_7c = 0;
  }
  pcStack_24 = FUN_0044bbd0;
  pcStack_28 = (code *)0x2;
  puStack_30 = local_fbc;
  iStack_2c = 0x7a0;
  local_78 = 0;
  local_8 = (uint)local_8._1_3_ << 8;
  puStack_34 = (undefined1 *)0x4493be;
  FUN_00605da0();
  ExceptionList = local_10;
  return;
}


