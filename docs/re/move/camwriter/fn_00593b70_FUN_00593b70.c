// FUN_00593b70  entry=00593b70  size=1858 bytes

void __fastcall FUN_00593b70(int param_1)

{
  undefined2 uVar1;
  uint uVar2;
  bool bVar3;
  undefined4 uVar4;
  undefined2 *puVar5;
  short *psVar6;
  DWORD DVar7;
  undefined4 *puVar8;
  int iVar9;
  int *piVar10;
  short *psVar11;
  undefined4 *puVar12;
  int local_1c;
  undefined4 local_18;
  int iStack_14;
  int iStack_10;
  
  if ((*(int *)(param_1 + 0x450) == 0) && (*(int *)(param_1 + 0x19a8) == 0)) {
    uVar4 = FUN_005ec240();
    if ((*(char *)(param_1 + 0x180b) != '\0') &&
       (*(int *)(*(int *)(*(int *)(param_1 + 0x468) + 4) + 0xb0) != 0)) {
      FUN_005e2a30(10,0);
    }
    FUN_005ec230(uVar4);
  }
  if ((*(int *)(param_1 + 0x1a38) != 0) && (DAT_006d31c4 == '\0')) {
    uVar4 = *(undefined4 *)(&DAT_00664070 + *(int *)(param_1 + 0x1a38) * 4);
    bVar3 = false;
    *(undefined4 *)(param_1 + 0x44c) = uVar4;
    *(undefined4 *)(param_1 + 0x448) = uVar4;
    FUN_005946d0();
    uVar2 = *(uint *)(param_1 + 0x1a38);
    if (uVar2 == 1) {
      *(int *)(param_1 + 0x19a8) = *(int *)(param_1 + 0x19a8) + *(int *)(param_1 + 0x450);
      *(undefined1 *)(param_1 + 0x1a1f) = 0;
      *(undefined4 *)(param_1 + 0x450) = 0;
      *(undefined4 *)(param_1 + 0x19a4) = 0;
      switch(*(undefined4 *)(param_1 + 0x19a0)) {
      case 0:
        FUN_0044d0d0();
        break;
      case 1:
        FUN_0044d190();
        if (*(int *)(*(int *)(param_1 + 0x468) + 0x44) == 0) {
          *(int *)(param_1 + 0x19a0) = *(int *)(param_1 + 0x19a0) + 2;
        }
        break;
      case 2:
        FUN_0044d250();
        break;
      case 3:
        FUN_0044d310();
        *(undefined4 *)(param_1 + 0x45c) = 0;
      }
      *(int *)(param_1 + 0x19a0) = *(int *)(param_1 + 0x19a0) + 1;
    }
    else if (((1 < uVar2) && (uVar2 < 9)) &&
            ((*(char *)(param_1 + 0x1a1f) != '\0' ||
             (((*(int *)(param_1 + 0x43c) != 0 &&
               (*(char *)(*(int *)(param_1 + 0x43c) + 0x2d9) != '\0')) ||
              (*(int *)(param_1 + 0x440) != 0)))))) {
      piVar10 = (int *)(param_1 + 0x508);
      local_1c = 0;
      do {
        puVar8 = &local_18;
        puVar5 = (undefined2 *)(*piVar10 + 0x30);
        iVar9 = 0xb;
        do {
          uVar1 = *puVar5;
          puVar5 = puVar5 + 0x56;
          *(undefined2 *)puVar8 = uVar1;
          puVar8 = (undefined4 *)((int)puVar8 + 2);
          iVar9 = iVar9 + -1;
        } while (iVar9 != 0);
        FUN_0044d3d0(local_1c);
        if (*(char *)(param_1 + 0x1a1f) != '\0') {
          psVar11 = (short *)&local_18;
          psVar6 = (short *)(*piVar10 + 0x30);
          iVar9 = 0xb;
          do {
            bVar3 = (bool)(bVar3 | *psVar11 != *psVar6);
            psVar11 = psVar11 + 1;
            psVar6 = psVar6 + 0x56;
            iVar9 = iVar9 + -1;
          } while (iVar9 != 0);
        }
        local_1c = local_1c + 1;
        piVar10 = piVar10 + 200;
      } while (local_1c < 2);
    }
    if ((*(int *)(param_1 + 0x19a0) != 4) || (*(int *)(param_1 + 0x19c0) == 0)) {
      iVar9 = 2;
      do {
        FUN_005b6ba0();
        iVar9 = iVar9 + -1;
      } while (iVar9 != 0);
    }
    FUN_005946f0();
    if (bVar3) {
      uVar4 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_00606220();
      }
      FUN_005ec230(uVar4);
    }
  }
  if (*(int *)(param_1 + 0x19a0) == 4) {
    *(undefined4 *)(param_1 + 0x44c) = 7;
    *(undefined4 *)(param_1 + 0x448) = 7;
    iVar9 = *(int *)(param_1 + 0x1820) + -0xb0000;
    if (*(int *)(param_1 + 0x45c) != 0) {
      iVar9 = -iVar9;
    }
    *(int *)(param_1 + 0x16a0) = iVar9;
    *(undefined4 *)(param_1 + 0x16a4) = 0;
    *(undefined4 *)(param_1 + 0x16a8) = 0;
  }
  *(undefined1 *)(param_1 + 0x460) = 0;
  *(byte *)(param_1 + 0x461) = *(byte *)(param_1 + 0x461) & 0x38;
  *(undefined4 *)(param_1 + 0x1994) = 0;
  *(undefined4 *)(param_1 + 0x1998) = 0;
  *(undefined4 *)(param_1 + 0x454) = 0;
  *(undefined4 *)(param_1 + 0x19dc) = 0;
  *(undefined4 *)(param_1 + 0x434) = 0;
  *(undefined4 *)(param_1 + 0x43c) = 0;
  *(undefined4 *)(param_1 + 0x440) = 0;
  *(undefined4 *)(param_1 + 0x438) = 0;
  *(undefined4 *)(param_1 + 0x444) = 0;
  FUN_005946f0();
  DVar7 = timeGetTime();
  *(DWORD *)(param_1 + 0x1a34) = DVar7;
  *(undefined4 *)(param_1 + 0x1a38) = 0;
  *(byte *)(param_1 + 0x461) = *(byte *)(param_1 + 0x461) & 0xcf;
  *(undefined1 *)(param_1 + 0x1a1f) = 0;
  DAT_006d31c0 = 0;
  DAT_006d31bc = 0;
  *(undefined4 *)(param_1 + 0x27ec) = 0;
  if (DAT_006d31c4 == '\0') {
    FUN_005bbf10(param_1 + 0x27dc,0);
    *(undefined4 *)(param_1 + 0x27e0) = 0;
    FUN_005bbf10(param_1 + 0x27e4,0);
    *(undefined4 *)(param_1 + 0x27e8) = 0;
  }
  else {
    puVar8 = *(undefined4 **)(param_1 + 0x27dc);
    puVar12 = (undefined4 *)(-(uint)(param_1 != 0) & (uint)(param_1 + 0x434));
    for (iVar9 = 0xc; iVar9 != 0; iVar9 = iVar9 + -1) {
      *puVar12 = *puVar8;
      puVar8 = puVar8 + 1;
      puVar12 = puVar12 + 1;
    }
    FUN_00591120(param_1);
  }
  (**(code **)(*(int *)(param_1 + 0x1610) + 4))();
  uVar4 = FUN_005b8f20();
  *(undefined4 *)(param_1 + 0x438) = uVar4;
  iVar9 = 2;
  do {
    FUN_005b70e0();
    iVar9 = iVar9 + -1;
  } while (iVar9 != 0);
  iVar9 = 2;
  do {
    FUN_005b73a0();
    iVar9 = iVar9 + -1;
  } while (iVar9 != 0);
  (**(code **)(*(int *)(param_1 + 0xaac) + 4))();
  (**(code **)(*(int *)(param_1 + 0xe74) + 4))();
  (**(code **)(*(int *)(param_1 + 0x123c) + 4))();
  *(undefined4 *)(param_1 + 0x458) = 0;
  local_18 = *(undefined4 *)(param_1 + 0x1614);
  iStack_14 = *(undefined4 *)(param_1 + 0x1618);
  iStack_10 = *(int *)(param_1 + 0x161c) + 0x500000;
  FUN_005f5740(&local_18);
  local_18 = *(undefined4 *)(param_1 + 0x1614);
  iStack_10 = *(undefined4 *)(param_1 + 0x161c);
  iStack_14 = *(int *)(param_1 + 0x1618) + 0xa0000;
  FUN_005f57a0(&local_18);
  FUN_005f5800(0x3c0000);
  iVar9 = *(int *)(param_1 + 0x448);
  if (iVar9 == 2) {
    if (*(int *)(param_1 + 0x450) != 0) {
      uVar4 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_004e94c0(*(undefined4 *)(param_1 + 0x478),*(undefined4 *)(param_1 + 0x798));
      }
      FUN_005ec230(uVar4);
    }
  }
  else if (((iVar9 != 3) && (iVar9 != 6)) && ((iVar9 != 4 && (iVar9 != 5)))) {
    return;
  }
  iVar9 = FUN_005ec250();
  if ((int)(iVar9 * 1000 + (iVar9 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 0x32) {
    if (*(int *)(param_1 + 0x45c) == 0) {
      uVar4 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_00606220();
        FUN_005ec230(uVar4);
        return;
      }
    }
    else {
      uVar4 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_00606220();
        FUN_005ec230(uVar4);
        return;
      }
    }
  }
  else {
    switch(*(undefined4 *)(param_1 + 0x448)) {
    case 2:
      if (*(int *)(param_1 + 0x19a0) == 0) {
        uVar4 = FUN_005ec240();
        if (*(char *)(param_1 + 0x180b) != '\0') {
          FUN_00606220();
          FUN_005ec230(uVar4);
          return;
        }
      }
      else {
        uVar4 = FUN_005ec240();
        if (*(char *)(param_1 + 0x180b) != '\0') {
          FUN_00606220();
          FUN_005ec230(uVar4);
          return;
        }
      }
      break;
    case 3:
      uVar4 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_00606220();
        FUN_005ec230(uVar4);
        return;
      }
      break;
    case 4:
      if (*(int *)(param_1 + 0x45c) == 0) {
        uVar4 = FUN_005ec240();
        if (*(char *)(param_1 + 0x180b) != '\0') {
          FUN_00606220();
          FUN_005ec230(uVar4);
          return;
        }
      }
      else {
        uVar4 = FUN_005ec240();
        if (*(char *)(param_1 + 0x180b) != '\0') {
          FUN_00606220();
          FUN_005ec230(uVar4);
          return;
        }
      }
      break;
    case 5:
      uVar4 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_00606220();
      }
      break;
    case 6:
      uVar4 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_00606220();
        FUN_005ec230(uVar4);
        return;
      }
      break;
    default:
      goto switchD_00594137_default;
    }
  }
  FUN_005ec230(uVar4);
switchD_00594137_default:
  return;
}


