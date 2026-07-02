// FUN_005b1500  entry=005b1500  size=1778 bytes

char __fastcall FUN_005b1500(int param_1)

{
  char cVar1;
  bool bVar2;
  undefined4 uVar3;
  uint uVar4;
  int iVar5;
  int *piVar6;
  int iVar7;
  int iVar8;
  undefined1 *puVar9;
  int iVar10;
  uint uVar11;
  uint uVar12;
  uint uVar13;
  int iVar14;
  undefined4 uVar15;
  undefined4 uVar16;
  char local_35;
  int local_34;
  int local_30;
  int local_2c;
  int local_28;
  int local_24;
  int local_20;
  int local_1c;
  int local_18;
  undefined4 local_14;
  undefined1 local_c [12];
  
  local_35 = '\x01';
  iVar14 = *(int *)(*(int *)(param_1 + 400) + 0x40);
  if ((iVar14 == 0) || (*(int *)(iVar14 + 700) != 0)) {
    iVar14 = *(int *)(param_1 + 0x150);
    if (iVar14 != 0) {
      uVar4 = *(int *)(iVar14 + 4) + *(int *)(iVar14 + 0x3a4);
      uVar11 = (int)uVar4 >> 0x1f;
      iVar5 = MulDiv((uVar4 ^ uVar11) - uVar11,
                     (int)(0x3200000 / (longlong)(*(int *)(iVar14 + 0x14c) + 100)),
                     *(int *)(*(int *)(param_1 + 0x18c) + 0x1820));
      if (iVar5 < 0x40001) {
        uVar4 = *(int *)(iVar14 + 4) + *(int *)(iVar14 + 0x3a4);
        uVar11 = (int)uVar4 >> 0x1f;
        iVar5 = MulDiv((uVar4 ^ uVar11) - uVar11,
                       (int)(0x3200000 / (longlong)(*(int *)(iVar14 + 0x14c) + 100)),
                       *(int *)(*(int *)(param_1 + 0x18c) + 0x1820));
      }
      else {
        iVar5 = 0x40000;
      }
      uVar16 = 0;
      uVar15 = 0;
      uVar3 = FUN_005a44f0(*(undefined4 *)(param_1 + 0x2b8));
      FUN_00590aa0(uVar3,uVar15,uVar16);
      FUN_00590aa0(local_24 - *(int *)(iVar14 + 4),local_20 - *(int *)(iVar14 + 8),
                   local_1c - *(int *)(iVar14 + 0xc));
      uVar3 = FUN_005ee080(local_18,local_14);
      piVar6 = (int *)FUN_005ee0f0(iVar5,uVar3);
      FUN_00590aa0(*piVar6 + *(int *)(iVar14 + 4),*(int *)(iVar14 + 8) + piVar6[1],
                   piVar6[2] + *(int *)(iVar14 + 0xc));
      if (iVar14 == *(int *)(*(int *)(param_1 + 400) + 0x4c)) {
LAB_005b1903:
        local_18 = (local_30 + *(int *)(iVar14 + 4)) / 2;
        iVar5 = *(int *)(param_1 + 0x218);
        iVar8 = (*(int *)(iVar14 + 0xc) + local_28) / 2;
        iVar10 = (*(int *)(iVar14 + 8) + local_2c) / 2;
        iVar7 = iVar5;
        if (iVar5 <= iVar8) {
          iVar7 = iVar8;
        }
        local_34 = *(int *)(param_1 + 0x224);
        if ((iVar7 <= local_34) && (local_34 = iVar5, iVar5 <= iVar8)) {
          local_34 = iVar8;
        }
        iVar5 = *(int *)(param_1 + 0x214);
        iVar7 = iVar5;
        if (iVar5 <= iVar10) {
          iVar7 = iVar10;
        }
        iVar8 = *(int *)(param_1 + 0x220);
        if ((iVar7 <= iVar8) && (iVar8 = iVar5, iVar5 <= iVar10)) {
          iVar8 = iVar10;
        }
        iVar5 = *(int *)(param_1 + 0x210);
        iVar7 = iVar5;
        if (iVar5 <= local_18) {
          iVar7 = local_18;
        }
        iVar10 = *(int *)(param_1 + 0x21c);
        if ((iVar7 <= *(int *)(param_1 + 0x21c)) && (iVar10 = iVar5, iVar5 <= local_18)) {
          iVar10 = local_18;
        }
        FUN_00590aa0(iVar10,iVar8,local_34);
        FUN_005a89c0(&local_18,0x5a);
        iVar5 = FUN_005b3c90(0,0x29999);
        if (*(int *)(param_1 + 0xe4 +
                    (*(int *)(iVar14 + 0x2b8) * 0xb + *(int *)(iVar14 + 0x2c4)) * 4) < iVar5) {
          FUN_005aafd0(0);
        }
      }
      else {
        if (iVar14 == *(int *)(*(int *)(iVar14 + 400) + 0x40)) {
          uVar4 = *(int *)(param_1 + 4) - local_30;
          uVar11 = (int)uVar4 >> 0x1f;
          if ((((int)((uVar4 ^ uVar11) - uVar11) < 0x20000) &&
              (uVar4 = *(int *)(param_1 + 8) - local_2c, uVar11 = (int)uVar4 >> 0x1f,
              (int)((uVar4 ^ uVar11) - uVar11) < 0x20000)) &&
             (uVar4 = *(int *)(param_1 + 0xc) - local_28, uVar11 = (int)uVar4 >> 0x1f,
             (int)((uVar4 ^ uVar11) - uVar11) < 0x20000)) {
            bVar2 = true;
          }
          else {
            bVar2 = false;
          }
          if (bVar2) {
            iVar5 = *(int *)(*(int *)(param_1 + 0x184) + 0x318);
            if (iVar5 == 0) {
              puVar9 = &LAB_004b0000;
            }
            else {
              puVar9 = (undefined1 *)((-(uint)(iVar5 != 1) & 0xffd80000) + 0x280000);
            }
            uVar4 = *(int *)(iVar14 + 4) - *(int *)(iVar14 + 0x3a4);
            uVar11 = (int)uVar4 >> 0x1f;
            if (((int)puVar9 < (int)((uVar4 ^ uVar11) - uVar11)) || (600 < *(int *)(iVar14 + 0x14c))
               ) goto LAB_005b1903;
          }
        }
        uVar4 = local_2c - *(int *)(param_1 + 8);
        uVar11 = (int)uVar4 >> 0x1f;
        if ((int)((uVar4 ^ uVar11) - uVar11) < 0x5999) {
          if (*(int *)(param_1 + 0x2b8) == *(int *)(iVar14 + 0x2b8)) {
            iVar5 = FUN_005b1c40();
          }
          else {
            iVar5 = FUN_005b1c60();
          }
          iVar7 = FUN_005b1c40();
          if (((iVar7 < iVar5) &&
              (iVar5 = *(int *)(param_1 + 4), uVar4 = iVar5 - local_30 >> 0x1f,
              (int)((iVar5 - local_30 ^ uVar4) - uVar4) < 0x30000)) &&
             (uVar4 = local_30 - *(int *)(iVar14 + 4), uVar12 = (int)uVar4 >> 0x1f,
             uVar11 = iVar5 - *(int *)(iVar14 + 4), uVar13 = (int)uVar11 >> 0x1f,
             (int)((uVar11 ^ uVar13) - uVar13) < (int)((uVar4 ^ uVar12) - uVar12))) {
            local_30 = iVar5;
          }
        }
        iVar5 = *(int *)(param_1 + 0x218);
        iVar7 = iVar5;
        if (iVar5 <= local_28) {
          iVar7 = local_28;
        }
        local_34 = *(int *)(param_1 + 0x224);
        if ((iVar7 <= local_34) && (local_34 = iVar5, iVar5 <= local_28)) {
          local_34 = local_28;
        }
        iVar5 = *(int *)(param_1 + 0x214);
        iVar7 = iVar5;
        if (iVar5 <= local_2c) {
          iVar7 = local_2c;
        }
        iVar8 = *(int *)(param_1 + 0x220);
        if ((iVar7 <= iVar8) && (iVar8 = iVar5, iVar5 <= local_2c)) {
          iVar8 = local_2c;
        }
        iVar5 = *(int *)(param_1 + 0x210);
        iVar7 = iVar5;
        if (iVar5 <= local_30) {
          iVar7 = local_30;
        }
        iVar10 = *(int *)(param_1 + 0x21c);
        if ((iVar7 <= iVar10) && (iVar10 = iVar5, iVar5 <= local_30)) {
          iVar10 = local_30;
        }
        FUN_00590aa0(iVar10,iVar8,local_34);
        FUN_005a89c0(&local_18,0x5a);
        if (iVar14 == *(int *)(*(int *)(iVar14 + 400) + 0x40)) {
          iVar5 = FUN_005ec250();
          if (*(int *)(param_1 + 0xe4 +
                      (*(int *)(iVar14 + 0x2b8) * 0xb + *(int *)(iVar14 + 0x2c4)) * 4) <
              (int)((iVar5 * 0x333 >> 0x1f & 0x7fU) + iVar5 * 0x333) >> 7) {
            iVar14 = *(int *)(*(int *)(param_1 + 0x184) + 0x31c);
            if (iVar14 == 0) {
              iVar14 = 0x14;
            }
            else {
              iVar5 = *(int *)(*(int *)(param_1 + 0x184) + 0x200);
              if (iVar14 == 1) {
                iVar14 = (-(uint)(iVar5 != param_1) & 0xfffffed4) + 400;
              }
              else {
                iVar14 = (-(uint)(iVar5 != param_1) & 0xfffffda8) + 800;
              }
            }
            iVar5 = FUN_005ec250();
            if ((int)(iVar5 * 1000 + (iVar5 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar14) {
              FUN_005aafd0(0);
            }
          }
        }
      }
      goto LAB_005b1b0b;
    }
    if (*(int *)(*(int *)(param_1 + 400) + 0x4c) != 0) {
      cVar1 = FUN_0058fb50((int *)(param_1 + 4));
      if ((cVar1 == '\0') ||
         (((-1 < *(int *)(param_1 + 4)) - 1 & 0xfffffffe) + 1 !=
          ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      if (bVar2) {
        iVar14 = *(int *)(*(int *)(param_1 + 400) + 0x4c);
        piVar6 = (int *)(iVar14 + 4);
        cVar1 = FUN_0058fb50(piVar6);
        if ((cVar1 == '\0') ||
           (((-1 < *piVar6) - 1 & 0xfffffffe) + 1 ==
            ((-1 < *(int *)(iVar14 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
          bVar2 = false;
        }
        else {
          bVar2 = true;
        }
        if (bVar2) {
          FUN_005b0040();
          goto LAB_005b1b0b;
        }
      }
    }
    if (*(int *)(param_1 + 0x2c8) == 4) {
      local_35 = '\0';
      goto LAB_005b1b0b;
    }
    FUN_005b3b20(local_c);
    uVar3 = FUN_005b1330(&local_18,param_1 + 0x210);
  }
  else {
    uVar3 = FUN_005b3b20(&local_18);
  }
  FUN_005a89c0(uVar3,0x5a);
LAB_005b1b0b:
  if (local_35 == '\0') {
    switch(*(int *)(param_1 + 0x2c8) + -2) {
    case 0:
    case 1:
      cVar1 = FUN_005b41b0();
      return cVar1;
    case 2:
      cVar1 = FUN_005b4a80();
      return cVar1;
    case 3:
    case 4:
      cVar1 = thunk_FUN_005b41b0();
      return cVar1;
    case 5:
    case 9:
      cVar1 = thunk_FUN_005b41b0();
      return cVar1;
    case 6:
    case 0x10:
      cVar1 = thunk_FUN_005b41b0();
      return cVar1;
    case 7:
      cVar1 = FUN_005b41b0();
      return cVar1;
    case 8:
      cVar1 = thunk_FUN_005b41b0();
      return cVar1;
    case 10:
    case 0xc:
      cVar1 = FUN_005b41b0();
      return cVar1;
    case 0xb:
    case 0xe:
    case 0xf:
      cVar1 = thunk_FUN_005b41b0();
      return cVar1;
    case 0xd:
      local_35 = thunk_FUN_005b41b0();
    }
  }
  return local_35;
}


