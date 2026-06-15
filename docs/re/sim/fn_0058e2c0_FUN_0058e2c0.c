// FUN_0058e2c0  entry=0058e2c0  size=2526 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_0058e2c0(int param_1)

{
  uint *puVar1;
  bool bVar2;
  char cVar3;
  undefined4 uVar4;
  int iVar5;
  int *piVar6;
  int iVar7;
  uint uVar8;
  int iVar9;
  int *piVar10;
  int iVar11;
  undefined8 local_78;
  int local_70;
  int local_6c;
  int local_68;
  int local_64;
  int local_5c;
  int local_58;
  int local_54;
  int local_50 [4];
  int local_40;
  int local_3c;
  int local_38 [4];
  int local_28;
  int local_24;
  int local_20 [7];
  
  FUN_00606220();
  *(undefined4 *)(param_1 + 0x58) = *(undefined4 *)(param_1 + 0x54);
  if (*(int *)(param_1 + 0x5c) != 0) {
    *(int *)(param_1 + 0x5c) = *(int *)(param_1 + 0x5c) + -1;
  }
  if (*(int *)(param_1 + 0x70) != 0) {
    *(int *)(param_1 + 0x70) = *(int *)(param_1 + 0x70) + -1;
  }
  if (*(int *)(param_1 + 0x68) != 0) {
    *(int *)(param_1 + 0x68) = *(int *)(param_1 + 0x68) + -1;
  }
  if ((*(int *)(param_1 + 0x68) == 0) && (iVar5 = *(int *)(param_1 + 0x6c), iVar5 != 0)) {
    *(int *)(param_1 + 0x6c) = iVar5 + -1;
    *(int *)(param_1 + 8) =
         *(int *)(param_1 + 8) + (*(int *)(param_1 + 0xa0) - *(int *)(param_1 + 8)) / iVar5;
    *(int *)(param_1 + 4) =
         *(int *)(param_1 + 4) + (*(int *)(param_1 + 0x9c) - *(int *)(param_1 + 4)) / iVar5;
    *(int *)(param_1 + 0xc) =
         *(int *)(param_1 + 0xc) + (*(int *)(param_1 + 0xa4) - *(int *)(param_1 + 0xc)) / iVar5;
  }
  else if (*(char *)(param_1 + 99) == '\0') {
    piVar6 = (int *)(param_1 + 4);
    puVar1 = (uint *)(param_1 + 0x20);
    local_6c = *(int *)(param_1 + 0x20) + *(int *)(param_1 + 4);
    local_68 = *(int *)(param_1 + 8) + *(int *)(param_1 + 0x24);
    local_50[2] = *(int *)(param_1 + 0xc) + *(int *)(param_1 + 0x28);
    iVar5 = *piVar6;
    iVar9 = *(int *)(param_1 + 8);
    iVar7 = *(int *)(param_1 + 0xc);
    iVar11 = iVar5;
    if (local_6c < iVar5) {
      iVar11 = local_6c;
      local_6c = iVar5;
    }
    iVar5 = iVar9;
    if (local_68 < iVar9) {
      iVar5 = local_68;
      local_68 = iVar9;
    }
    local_70 = iVar7;
    local_64 = local_50[2];
    if (local_50[2] < iVar7) {
      local_70 = local_50[2];
      local_64 = iVar7;
    }
    local_70 = local_70 + -0x23d7;
    local_78 = (double)CONCAT44(iVar5 + -0x23d7,iVar11 + -0x23d7);
    FUN_00590b10(0x23d7);
    FUN_00590ac0(&local_78);
    FUN_00590ac0(&local_6c);
    iVar5 = *(int *)(param_1 + 0x1d4);
    *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + 0x23d7;
    if (*(char *)(iVar5 + 0x5fac) != '\0') {
      if (((((*piVar6 < *(int *)(iVar5 + 0x1828)) || (*(int *)(iVar5 + 0x1834) < *piVar6)) ||
           (*(int *)(param_1 + 8) < *(int *)(iVar5 + 0x182c))) ||
          ((*(int *)(iVar5 + 0x1838) < *(int *)(param_1 + 8) ||
           (*(int *)(param_1 + 0xc) < *(int *)(iVar5 + 0x1830))))) ||
         (*(int *)(iVar5 + 0x183c) < *(int *)(param_1 + 0xc))) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      if (!bVar2) {
        cVar3 = FUN_005f3b80(piVar6,0x23d7,puVar1,0x8000);
        if (cVar3 != '\0') {
          local_50[3] = *piVar6 + *puVar1;
          local_40 = *(int *)(param_1 + 0x24) + *(int *)(param_1 + 8);
          local_3c = *(int *)(param_1 + 0x28) + *(int *)(param_1 + 0xc);
          iVar5 = *piVar6;
          iVar9 = *(int *)(param_1 + 8);
          iVar7 = *(int *)(param_1 + 0xc);
          local_50[0] = iVar5;
          if (local_50[3] < iVar5) {
            local_50[0] = local_50[3];
            local_50[3] = iVar5;
          }
          local_50[1] = iVar9;
          if (local_40 < iVar9) {
            local_50[1] = local_40;
            local_40 = iVar9;
          }
          local_50[2] = iVar7;
          if (local_3c < iVar7) {
            local_50[2] = local_3c;
            local_3c = iVar7;
          }
          local_50[0] = local_50[0] + -0x23d7;
          local_50[1] = local_50[1] + -0x23d7;
          local_50[2] = local_50[2] + -0x23d7;
          FUN_00590b10(0x23d7);
          piVar6 = local_50;
          piVar10 = local_20;
          for (iVar5 = 6; iVar5 != 0; iVar5 = iVar5 + -1) {
            *piVar10 = *piVar6;
            piVar6 = piVar6 + 1;
            piVar10 = piVar10 + 1;
          }
        }
        piVar6 = (int *)(param_1 + 4);
        cVar3 = FUN_005f3b80(piVar6,0x23d7,puVar1,0x7ae1);
        if (cVar3 != '\0') {
          local_50[3] = *puVar1 + *piVar6;
          local_40 = *(int *)(param_1 + 0x24) + *(int *)(param_1 + 8);
          local_3c = *(int *)(param_1 + 0xc) + *(int *)(param_1 + 0x28);
          iVar5 = *piVar6;
          iVar9 = *(int *)(param_1 + 8);
          iVar7 = *(int *)(param_1 + 0xc);
          local_50[0] = iVar5;
          if (local_50[3] < iVar5) {
            local_50[0] = local_50[3];
            local_50[3] = iVar5;
          }
          local_50[1] = iVar9;
          if (local_40 < iVar9) {
            local_50[1] = local_40;
            local_40 = iVar9;
          }
          local_50[2] = iVar7;
          if (local_3c < iVar7) {
            local_50[2] = local_3c;
            local_3c = iVar7;
          }
          local_50[0] = local_50[0] + -0x23d7;
          local_50[1] = local_50[1] + -0x23d7;
          local_50[2] = local_50[2] + -0x23d7;
          FUN_00590b10(0x23d7);
          piVar6 = local_50;
          piVar10 = local_20;
          for (iVar5 = 6; iVar5 != 0; iVar5 = iVar5 + -1) {
            *piVar10 = *piVar6;
            piVar6 = piVar6 + 1;
            piVar10 = piVar10 + 1;
          }
          if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180a) != '\0') {
            FUN_00590f00();
          }
        }
      }
    }
    iVar5 = *(int *)(*(int *)(param_1 + 0x1d4) + 0x17f8);
    iVar9 = *(int *)(*(int *)(param_1 + 0x1d4) + 0x17f4);
    while (iVar5 != 0) {
      iVar5 = iVar5 + -1;
      cVar3 = FUN_00590b30(iVar9 + 0x30);
      if ((cVar3 == '\0') ||
         (cVar3 = FUN_005efac0(iVar9 + 0x48,param_1 + 4,0x23d7,puVar1,*(undefined4 *)(iVar9 + 0x54),
                               &local_5c), cVar3 == '\0')) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      iVar7 = iVar9;
      if (bVar2) {
        local_38[3] = *puVar1 + *(int *)(param_1 + 4);
        local_28 = *(int *)(param_1 + 0x24) + *(int *)(param_1 + 8);
        local_24 = *(int *)(param_1 + 0xc) + *(int *)(param_1 + 0x28);
        iVar5 = *(int *)(param_1 + 4);
        iVar7 = *(int *)(param_1 + 8);
        iVar11 = *(int *)(param_1 + 0xc);
        local_38[0] = iVar5;
        if (local_38[3] < iVar5) {
          local_38[0] = local_38[3];
          local_38[3] = iVar5;
        }
        local_38[1] = iVar7;
        if (local_28 < iVar7) {
          local_38[1] = local_28;
          local_28 = iVar7;
        }
        local_38[2] = iVar11;
        if (local_24 < iVar11) {
          local_38[2] = local_24;
          local_24 = iVar11;
        }
        local_38[1] = local_38[1] + -0x23d7;
        local_38[0] = local_38[0] + -0x23d7;
        local_38[2] = local_38[2] + -0x23d7;
        FUN_00590b10(0x23d7);
        iVar5 = *(int *)(param_1 + 0x1d4);
        piVar6 = local_38;
        piVar10 = local_20;
        for (iVar7 = 6; iVar7 != 0; iVar7 = iVar7 + -1) {
          *piVar10 = *piVar6;
          piVar6 = piVar6 + 1;
          piVar10 = piVar10 + 1;
        }
        local_50[0] = *(int *)(iVar5 + 0x17f4) + -0x58;
        local_50[1] = *(int *)(iVar5 + 0x17f8) + 1;
        if (*(int *)(iVar9 + 0x54) == 0x7ae1) {
          if (*(char *)(iVar5 + 0x180a) != '\0') {
            FUN_00590f00();
          }
        }
        else if (*(int *)(iVar9 + 0x54) == 0x9eb8) {
          if (*(char *)(iVar5 + 0x180a) != '\0') {
            FUN_00590f00();
          }
          iVar5 = *(int *)(param_1 + 4);
          if (((-1 < (int)*puVar1) - 1 & 0xfffffffe) + 1 != ((-1 < iVar5) - 1 & 0xfffffffe) + 1) {
            iVar7 = *(int *)(param_1 + 0x1d4);
            if ((((iVar5 < *(int *)(iVar7 + 0x1828)) || (*(int *)(iVar7 + 0x1834) < iVar5)) ||
                (*(int *)(param_1 + 8) < *(int *)(iVar7 + 0x182c))) ||
               (((*(int *)(iVar7 + 0x1838) < *(int *)(param_1 + 8) ||
                 (*(int *)(param_1 + 0xc) < *(int *)(iVar7 + 0x1830))) ||
                (*(int *)(iVar7 + 0x183c) < *(int *)(param_1 + 0xc))))) {
              bVar2 = false;
            }
            else {
              bVar2 = true;
            }
            if ((bVar2) && (*(int *)(iVar7 + 0x448) == 0)) {
              FUN_005909f0(1);
              uVar8 = (int)*(uint *)(param_1 + 8) >> 0x1f;
              if ((int)((*(uint *)(param_1 + 8) ^ uVar8) - uVar8) < 0x36b85) {
                if ((*(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) & 0x60) == 0) {
                  uVar4 = FUN_005ec240();
                  if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180b) != '\0') {
                    FUN_004ebe50();
                    FUN_005ec230(uVar4);
                    uVar4 = 0x1a;
                    goto LAB_0058e8c7;
                  }
                }
                else {
                  uVar4 = FUN_005ec240();
                  if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180b) != '\0') {
                    FUN_004ebd20();
                  }
                }
                FUN_005ec230(uVar4);
                uVar4 = 0x1a;
              }
              else {
                uVar4 = 0x1b;
              }
LAB_0058e8c7:
              FUN_00594470(uVar4,0,1);
              *(undefined4 *)(param_1 + 0x50) = 0;
            }
          }
        }
        iVar7 = local_50[0];
        iVar5 = local_50[1];
        for (iVar11 = *(int *)(*(int *)(param_1 + 0x1d4) + 0x2ba8); local_50[0] = iVar7,
            local_50[1] = iVar5, iVar11 != 0; iVar11 = iVar11 + -1) {
          local_78 = (double)*(int *)(param_1 + 0x28);
          uVar4 = ftol();
          FUN_005babe0(iVar9,local_5c,local_58,uVar4);
          iVar7 = local_50[0];
          iVar5 = local_50[1];
        }
        *(int *)(param_1 + 0x80) = *(int *)(param_1 + 0x80) + 1;
      }
      iVar9 = iVar7 + 0x58;
    }
    *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + -0x23d7;
    *(uint *)(param_1 + 4) = *(int *)(param_1 + 4) + *puVar1;
    *(int *)(param_1 + 8) = *(int *)(param_1 + 8) + *(int *)(param_1 + 0x24);
    iVar5 = *(int *)(param_1 + 0xc) + *(int *)(param_1 + 0x28);
    *(int *)(param_1 + 0xc) = iVar5;
    if ((iVar5 < 0) || ((iVar5 == 0 && (*(int *)(param_1 + 0x28) < 0)))) {
      *(undefined4 *)(param_1 + 0xc) = 0;
      if ((*(int *)(param_1 + 0x28) < -0x51e) &&
         (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180a) != '\0')) {
        FUN_00590f00();
      }
      uVar8 = FUN_005edfa0(*puVar1,0xc51e);
      *puVar1 = uVar8;
      uVar4 = FUN_005edfa0(*(undefined4 *)(param_1 + 0x24),0xc51e);
      *(undefined4 *)(param_1 + 0x24) = uVar4;
      iVar5 = FUN_005edfa0(*(undefined4 *)(param_1 + 0x28),0x9c28);
      uVar8 = -iVar5;
      *(uint *)(param_1 + 0x28) = uVar8;
      if ((int)((uVar8 ^ (int)uVar8 >> 0x1f) - ((int)uVar8 >> 0x1f)) < 0x28f) {
        *(undefined4 *)(param_1 + 0x28) = 0;
      }
      *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) =
           *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) & 0x7f;
      *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) =
           *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) & 0xbf;
      *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) =
           *(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) & 0xdf;
      *(undefined1 *)(param_1 + 100) = 0;
      *(undefined1 *)(param_1 + 0x61) = 1;
    }
    else if ((iVar5 == 0) && (*(int *)(param_1 + 0x28) == 0)) {
      uVar8 = (int)*puVar1 >> 0x1f;
      if (((int)((*puVar1 ^ uVar8) - uVar8) < 0x22) &&
         (uVar8 = (int)*(uint *)(param_1 + 0x24) >> 0x1f,
         (int)((*(uint *)(param_1 + 0x24) ^ uVar8) - uVar8) < 0x22)) {
        *puVar1 = 0;
        *(undefined4 *)(param_1 + 0x24) = 0;
        *(undefined4 *)(param_1 + 0x28) = 0;
      }
      else {
        uVar4 = FUN_005ee080(*puVar1,*(undefined4 *)(param_1 + 0x24));
        piVar6 = (int *)FUN_005ee0f0(0x22,uVar4);
        *puVar1 = *puVar1 - *piVar6;
        *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) - piVar6[1];
        *(int *)(param_1 + 0x28) = *(int *)(param_1 + 0x28) - piVar6[2];
      }
    }
    else {
      *puVar1 = *puVar1 + DAT_0066c1b0;
      *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + DAT_0066c1b4;
      *(int *)(param_1 + 0x28) = *(int *)(param_1 + 0x28) + DAT_0066c1b8;
    }
    if (((*puVar1 == 0) && (*(int *)(param_1 + 0x24) == 0)) && (*(int *)(param_1 + 0x28) == 0)) {
      bVar2 = true;
    }
    else {
      bVar2 = false;
    }
    if (!bVar2) {
      iVar5 = FUN_005ee500(puVar1);
      if (iVar5 < 0x4000) {
        if (iVar5 < 0x226b) {
          if (0xc04 < iVar5) {
            *(uint *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + 2U & 0x1f;
            goto LAB_0058eb93;
          }
          if (0x222 < iVar5) {
            *(uint *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + 1U & 0x1f;
            goto LAB_0058eb93;
          }
          uVar8 = *(int *)(param_1 + 0x30) - 1U & 1;
          *(uint *)(param_1 + 0x30) = uVar8;
          if (uVar8 != 0) goto LAB_0058eb93;
          uVar8 = *(int *)(param_1 + 0x2c) + 1;
        }
        else {
          uVar8 = *(int *)(param_1 + 0x2c) + 3;
        }
        *(uint *)(param_1 + 0x2c) = uVar8 & 0x1f;
      }
      else {
        *(uint *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + 4U & 0x1f;
      }
    }
  }
LAB_0058eb93:
  FUN_0058fda0();
  uVar4 = FUN_005ee080(*(undefined4 *)(param_1 + 0x20),*(undefined4 *)(param_1 + 0x24));
  *(short *)(param_1 + 0x34) = (short)uVar4;
  if (((*(int *)(param_1 + 0x20) == 0) && (*(int *)(param_1 + 0x24) == 0)) &&
     (*(int *)(param_1 + 0x28) == 0)) {
    bVar2 = true;
  }
  else {
    bVar2 = false;
  }
  if (!bVar2) {
    if ((*(int *)(param_1 + 0xc) == 0) && (*(int *)(param_1 + 0x28) == 0)) {
      FUN_005ee0f0(0x10000,uVar4);
      local_5c = *(int *)(param_1 + 0x84) - *(int *)(param_1 + 4);
      local_58 = *(int *)(param_1 + 0x88) - *(int *)(param_1 + 8);
      local_54 = *(int *)(param_1 + 0x8c) - *(int *)(param_1 + 0xc);
      iVar5 = FUN_005ee500(&local_5c);
      if (iVar5 < 1) {
        uVar4 = 0;
      }
      else {
        uVar4 = FUN_005ee500(&local_5c);
      }
      piVar6 = (int *)FUN_005ee170(&local_78,uVar4);
      iVar5 = piVar6[1];
      iVar9 = piVar6[2];
      *(int *)(param_1 + 0x84) = *(int *)(param_1 + 4) + *piVar6;
      *(int *)(param_1 + 0x88) = iVar5 + *(int *)(param_1 + 8);
      *(int *)(param_1 + 0x8c) = iVar9 + *(int *)(param_1 + 0xc);
    }
    return;
  }
  *(undefined4 *)(param_1 + 0x84) = *(undefined4 *)(param_1 + 4);
  *(undefined4 *)(param_1 + 0x88) = *(undefined4 *)(param_1 + 8);
  *(undefined4 *)(param_1 + 0x8c) = *(undefined4 *)(param_1 + 0xc);
  return;
}


