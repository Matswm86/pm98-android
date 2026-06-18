// FUN_005b73a0  entry=005b73a0  size=4834 bytes

/* WARNING: Removing unreachable block (ram,0x005b7d19) */

void __fastcall FUN_005b73a0(int *param_1)

{
  int *piVar1;
  action *paVar2;
  action *paVar3;
  int iVar4;
  char cVar5;
  undefined2 uVar6;
  int *piVar7;
  int iVar8;
  undefined4 *puVar9;
  UnwindMapEntry *pUVar10;
  undefined4 uVar11;
  int iVar12;
  int *piVar13;
  action **ppaVar14;
  uint uVar15;
  uint uVar16;
  UnwindMapEntry *pUVar17;
  int iVar18;
  int *piVar19;
  action **ppaVar20;
  int iVar21;
  bool bVar22;
  UnwindMapEntry *local_a4;
  int local_9c;
  int local_98;
  undefined1 local_94;
  undefined1 local_93;
  undefined1 local_92;
  char local_8d;
  int local_8c;
  int local_88;
  undefined1 local_84;
  undefined1 local_83;
  undefined1 local_82;
  int local_80;
  UnwindMapEntry *local_7c;
  int *local_78;
  int local_74;
  int local_70;
  int local_6c;
  int local_68;
  int local_64;
  int local_60;
  int local_5c;
  undefined8 local_58;
  undefined4 local_48;
  int local_44;
  int local_3c [14];
  
  if (DAT_006d31c4 != '\0') {
    return;
  }
  local_78 = param_1;
  FUN_005b8690();
  iVar8 = param_1[0x4e];
  param_1[0xb8] = -1;
  iVar18 = *(int *)(iVar8 + 0x448);
  if (((iVar18 == 4) || ((iVar18 == 5 && (*(int *)(iVar8 + 0x19cc) != 0)))) &&
     (uVar15 = param_1[2], *(uint *)(iVar8 + 0x45c) != uVar15)) {
    local_9c = 1;
    iVar18 = iVar8 + uVar15 * -800;
    piVar19 = (int *)(iVar18 + 0x78c);
    iVar21 = (-(uint)((*(uint *)(iVar8 + 0x19a0) & 1) != uVar15) & 0xfffe0000) + 0x10000;
    local_98 = 0;
    local_94 = 0;
    local_93 = 0;
    iVar8 = param_1[1];
    local_92 = 0;
    *(undefined1 *)((int)&local_9c + *(int *)(*(int *)(iVar18 + 0x8f4) + 0x2c4)) = 1;
    local_8d = '\0';
    local_8c = 1;
    local_88 = 0;
    local_84 = 0;
    local_83 = 0;
    local_82 = 0;
    local_58 = (double)CONCAT44(iVar8 + -1,(undefined4)local_58);
    if (iVar8 != 0) {
      piVar7 = (int *)(*param_1 + 0x2c8);
      do {
        iVar8 = *piVar7;
        if ((iVar8 == 5) || (iVar8 == 6)) {
          local_6c = *(int *)(iVar18 + 0x790) + -1;
          if (*(int *)(iVar18 + 0x790) != 0) {
            piVar13 = (int *)(*piVar19 + 0x2c4);
            do {
              if ((piVar13[1] == 9) && (*(char *)((int)&local_9c + *piVar13) == '\0')) {
                *(undefined1 *)((int)&local_9c + *piVar13) = 1;
                *(undefined1 *)((int)&local_8c + piVar7[-1]) = 1;
                piVar1 = piVar7 + -0xb1;
                *piVar1 = piVar13[-0xb0];
                piVar7[-0xb0] = piVar13[-0xaf];
                piVar7[-0xaf] = piVar13[-0xae];
                *piVar1 = *piVar1 - iVar21;
              }
              piVar13 = piVar13 + 0xef;
              bVar22 = local_6c != 0;
              local_6c = local_6c + -1;
            } while (bVar22);
          }
        }
        else if (iVar8 == 10) {
          local_60 = *(int *)(iVar18 + 0x790) + -1;
          if (*(int *)(iVar18 + 0x790) != 0) {
            piVar13 = (int *)(*piVar19 + 0x2c4);
            do {
              if ((piVar13[1] == 10) && (*(char *)((int)&local_9c + *piVar13) == '\0')) {
                *(undefined1 *)((int)&local_9c + *piVar13) = 1;
                *(undefined1 *)((int)&local_8c + piVar7[-1]) = 1;
                piVar1 = piVar7 + -0xb1;
                *piVar1 = piVar13[-0xb0];
                piVar7[-0xb0] = piVar13[-0xaf];
                piVar7[-0xaf] = piVar13[-0xae];
                *piVar1 = *piVar1 - iVar21;
              }
              piVar13 = piVar13 + 0xef;
              bVar22 = local_60 != 0;
              local_60 = local_60 + -1;
            } while (bVar22);
          }
        }
        else if ((local_8d == '\0') &&
                (((iVar8 == 2 || (iVar8 == 3)) &&
                 (iVar8 = param_1[0x4e],
                 ((-1 < piVar7[-0x39]) - 1 & 0xfffffffe) + 1 ==
                 ((-1 < *(int *)(iVar8 + 0x16a4)) - 1 & 0xfffffffe) + 1)))) {
          iVar12 = *(int *)(iVar8 + 0x1820);
          uVar15 = piVar7[-4];
          *(undefined1 *)((int)&local_8c + piVar7[-1]) = 1;
          iVar12 = 0x8000 - iVar12;
          local_8d = '\x01';
          if (uVar15 != (*(uint *)(piVar7[-0x4f] + 0x19a0) & 1)) {
            iVar12 = -iVar12;
          }
          iVar8 = *(int *)(iVar8 + 0x16a4);
          piVar7[-0xb1] = iVar12;
          piVar7[-0xb0] = (((-1 < iVar8) - 1 & 0xfffffffe) + 1) * 0x40000;
          piVar7[-0xaf] = 0;
        }
        piVar7 = piVar7 + 0xef;
        bVar22 = local_58._4_4_ != 0;
        local_58 = (double)CONCAT44(local_58._4_4_ + -1,(undefined4)local_58);
      } while (bVar22);
    }
    local_60 = param_1[1] + -1;
    if (param_1[1] != 0) {
      piVar7 = (int *)(*param_1 + 0xb0);
      do {
        if (((piVar7[0x83] != 0) && (*(char *)((int)&local_8c + piVar7[0x85]) == '\0')) &&
           ((iVar8 = *piVar7, iVar8 != 0 &&
            ((*(char *)((int)&local_9c + *(int *)(iVar8 + 0x2c4)) == '\0' &&
             (cVar5 = FUN_005b04e0(iVar8 + 4), cVar5 != '\0')))))) {
          iVar8 = *piVar7;
          iVar12 = *(int *)(iVar8 + 0x2c4);
          *(undefined1 *)((int)&local_8c + piVar7[0x85]) = 1;
          piVar13 = piVar7 + -0x2b;
          *(undefined1 *)((int)&local_9c + iVar12) = 1;
          *piVar13 = *(int *)(iVar8 + 4);
          piVar7[-0x2a] = *(int *)(iVar8 + 8);
          piVar7[-0x29] = *(int *)(iVar8 + 0xc);
          *piVar13 = *piVar13 - iVar21;
        }
        piVar7 = piVar7 + 0xef;
        bVar22 = local_60 != 0;
        local_60 = local_60 + -1;
      } while (bVar22);
    }
    pUVar17 = (UnwindMapEntry *)*param_1;
    local_3c[1] = param_1[1] + -1;
    if (param_1[1] != 0) {
      pUVar17 = pUVar17 + 0x59;
      do {
        if ((((((pUVar17[-2].action != (action *)0x0) &&
               (*(char *)((int)&local_8c + (int)pUVar17[-1].action) == '\0')) &&
              (iVar8 = pUVar17->toState, iVar8 != 0xc)) && ((iVar8 != 0xd && (iVar8 != 0xe)))) &&
            (iVar8 != 0x10)) && (iVar8 != 0x11)) {
          local_7c = (UnwindMapEntry *)0x0;
          local_74 = 0x3e80000;
          pUVar10 = (UnwindMapEntry *)*piVar19;
          local_80 = 0;
          local_60 = *(int *)(iVar18 + 0x790) + -1;
          if (*(int *)(iVar18 + 0x790) != 0) {
            ppaVar20 = &pUVar10[1].action;
            do {
              if ((ppaVar20[0xac] != (action *)0x0) &&
                 (*(char *)((int)&local_9c + (int)ppaVar20[0xae]) == '\0')) {
                cVar5 = FUN_005b04e0(ppaVar20 + -2);
                if (cVar5 != '\0') {
                  local_6c = ((UnwindMapEntry *)(ppaVar20 + -1))->toState - pUVar17[-0x58].toState;
                  local_70 = (int)ppaVar20[-2] - (int)pUVar17[-0x59].action;
                  local_68 = (int)*ppaVar20 - (int)pUVar17[-0x58].action;
                  local_58 = (double)local_68;
                  iVar8 = ftol();
                  if (iVar8 < local_74) {
                    local_74 = iVar8;
                    local_7c = pUVar10;
                    local_80 = (int)ppaVar20[0xae];
                  }
                }
              }
              pUVar10 = (UnwindMapEntry *)&pUVar10[0x77].action;
              ppaVar20 = ppaVar20 + 0xef;
              bVar22 = local_60 != 0;
              local_60 = local_60 + -1;
              param_1 = local_78;
            } while (bVar22);
          }
          pUVar10 = local_7c;
          if (local_7c != (UnwindMapEntry *)0x0) {
            paVar2 = pUVar17[-1].action;
            ppaVar14 = &local_7c->action;
            *(undefined1 *)((int)&local_9c + local_80) = 1;
            ppaVar20 = &pUVar17[-0x59].action;
            paVar3 = *ppaVar14;
            *(undefined1 *)((int)&local_8c + (int)paVar2) = 1;
            *ppaVar20 = paVar3;
            pUVar17[-0x58].toState = pUVar10[1].toState;
            pUVar17[-0x58].action = pUVar10[1].action;
            *ppaVar20 = *ppaVar20 + -iVar21;
          }
        }
        pUVar17 = (UnwindMapEntry *)&pUVar17[0x77].action;
        bVar22 = local_3c[1] != 0;
        local_3c[1] = local_3c[1] + -1;
      } while (bVar22);
    }
    local_44 = param_1[1] + -1;
    if (param_1[1] != 0) {
      piVar7 = (int *)(*param_1 + 0x2c8);
      do {
        if ((piVar7[-3] != 0) && (*(char *)((int)&local_8c + piVar7[-1]) == '\0')) {
          local_7c = (UnwindMapEntry *)0x0;
          local_80 = 0x640000;
          pUVar10 = (UnwindMapEntry *)*piVar19;
          local_74 = 0;
          local_3c[1] = *(int *)(iVar18 + 0x790) + -1;
          if (*(int *)(iVar18 + 0x790) != 0) {
            ppaVar20 = &pUVar10[1].action;
            do {
              if ((ppaVar20[0xac] != (action *)0x0) &&
                 (*(char *)((int)&local_9c + (int)ppaVar20[0xae]) == '\0')) {
                pUVar17 = (UnwindMapEntry *)(ppaVar20 + -2);
                cVar5 = FUN_0058fb50(pUVar17);
                if ((cVar5 == '\0') ||
                   (((-1 < pUVar17->toState) - 1 & 0xfffffffe) + 1 ==
                    ((-1 < (int)ppaVar20[0xe6]) - 1 & 0xfffffffe) + 1)) {
                  bVar22 = false;
                }
                else {
                  bVar22 = true;
                }
                if (bVar22) {
                  local_6c = ((UnwindMapEntry *)(ppaVar20 + -1))->toState - piVar7[-0xb0];
                  local_70 = pUVar17->toState - piVar7[-0xb1];
                  pUVar17 = (UnwindMapEntry *)piVar7[-0xaf];
                  local_68 = (int)*ppaVar20 - (int)pUVar17;
                  local_58 = (double)local_68;
                  iVar8 = ftol();
                  if (iVar8 < local_80) {
                    local_80 = iVar8;
                    local_7c = pUVar10;
                    local_74 = (int)ppaVar20[0xae];
                  }
                }
              }
              pUVar10 = (UnwindMapEntry *)&pUVar10[0x77].action;
              ppaVar20 = ppaVar20 + 0xef;
              bVar22 = local_3c[1] != 0;
              local_3c[1] = local_3c[1] + -1;
            } while (bVar22);
          }
          iVar8 = local_74;
          pUVar10 = local_7c;
          if (local_7c == (UnwindMapEntry *)0x0) {
            iVar8 = *piVar7;
            if ((((iVar8 == 0xc) || (iVar8 == 0xd)) || (iVar8 == 0xe)) ||
               ((iVar8 == 0x10 || (iVar8 == 0x11)))) {
              *(undefined1 *)((int)&local_8c + piVar7[-1]) = 1;
              piVar7[-0xb1] = piVar7[-0x3a];
              piVar7[-0xb0] = piVar7[-0x39];
              piVar7[-0xaf] = piVar7[-0x38];
            }
            else {
              uVar15 = piVar7[-4];
              *(undefined1 *)((int)&local_8c + piVar7[-1]) = 1;
              iVar8 = *(int *)(piVar7[-0x4f] + 0x1820);
              if ((*(uint *)(piVar7[-0x4f] + 0x19a0) & 1) == uVar15) {
                iVar8 = -iVar8;
              }
              FUN_00590aa0(iVar8,0,0);
              piVar13 = piVar7 + -0xb1;
              *piVar13 = local_64;
              piVar7[-0xb0] = local_60;
              piVar7[-0xaf] = local_5c;
              iVar8 = FUN_005ec250();
              iVar8 = (int)(iVar8 * 0x1080 + (iVar8 * 0x1080 >> 0x1f & 0x7fU)) >> 7;
              if ((*(uint *)(piVar7[-0x4f] + 0x19a0) & 1) != piVar7[-4]) {
                iVar8 = -iVar8;
              }
              *piVar13 = *piVar13 + iVar8;
              iVar8 = FUN_005ec250();
              piVar7[-0xb0] =
                   piVar7[-0xb0] +
                   ((int)(iVar8 * 0x2800 + (iVar8 * 0x2800 >> 0x1f & 0x7fU)) >> 7) + -0x140000;
            }
          }
          else {
            ppaVar20 = &local_7c->action;
            *(undefined1 *)((int)&local_8c + piVar7[-1]) = 1;
            piVar13 = piVar7 + -0xb1;
            paVar2 = *ppaVar20;
            *(undefined1 *)((int)&local_9c + iVar8) = 1;
            *piVar13 = (int)paVar2;
            piVar7[-0xb0] = pUVar10[1].toState;
            piVar7[-0xaf] = (int)pUVar10[1].action;
            *piVar13 = *piVar13 +
                       ((-(uint)(piVar7[-4] != (*(uint *)(piVar7[-0x4f] + 0x19a0) & 1)) & 0x20000) -
                       0x10000);
          }
        }
        piVar7 = piVar7 + 0xef;
        bVar22 = local_44 != 0;
        local_44 = local_44 + -1;
        param_1 = local_78;
      } while (bVar22);
    }
    if (0 < param_1[1]) {
      iVar8 = 0;
      local_a4 = (UnwindMapEntry *)0x1;
      do {
        iVar18 = iVar8 + *param_1;
        puVar9 = (undefined4 *)FUN_00590ae0(&local_48,iVar18 + 4);
        uVar6 = FUN_005ee080(*puVar9,puVar9[1]);
        *(undefined2 *)(iVar18 + 0x34) = uVar6;
        *(undefined2 *)(iVar18 + 100) = uVar6;
        pUVar17 = local_a4;
        iVar18 = iVar8;
        if ((int)local_a4 < param_1[1]) {
          do {
            if (*(int *)(iVar18 + 0x678 + *param_1) != 0) {
              local_60 = 0;
              local_5c = 0;
              local_64 = iVar21;
              FUN_005ee3f0(iVar8 + 4 + *param_1,0x10000,&local_64);
            }
            pUVar17 = (UnwindMapEntry *)((int)&pUVar17->toState + 1);
            iVar18 = iVar18 + 0x3bc;
          } while ((int)pUVar17 < param_1[1]);
        }
        iVar8 = iVar8 + 0x3bc;
        bVar22 = (int)local_a4 < param_1[1];
        local_a4 = (UnwindMapEntry *)((int)&local_a4->toState + 1);
      } while (bVar22);
    }
    goto LAB_005b81d6;
  }
  if (iVar18 == 7) {
    if (*(int *)(iVar8 + 0x19a0) == 4) {
      iVar8 = *param_1;
      pUVar17 = (UnwindMapEntry *)(param_1[1] + -1);
      if (param_1[1] != 0) {
        do {
          if ((iVar8 != *(int *)(*(int *)(iVar8 + 0x18c) + 0x438)) &&
             ((*(int *)(iVar8 + 700) != 0 || (param_1[2] == *(int *)(param_1[0x4e] + 0x45c))))) {
            iVar18 = FUN_005ec250();
            iVar18 = (int)(iVar18 * 0x100 + (iVar18 * 0x100 >> 0x1f & 0x7fU)) >> 7;
            iVar21 = FUN_005ec250(iVar18);
            puVar9 = (undefined4 *)
                     FUN_005ee0f0((int)(iVar21 * 0xa00 + (iVar21 * 0xa00 >> 0x1f & 0x7fU)) >> 7,
                                  iVar18);
            *(undefined4 *)(iVar8 + 4) = *puVar9;
            *(undefined4 *)(iVar8 + 8) = puVar9[1];
            *(undefined4 *)(iVar8 + 0xc) = puVar9[2];
            *(undefined4 *)(iVar8 + 0x1e0) = *puVar9;
            *(undefined4 *)(iVar8 + 0x1e4) = puVar9[1];
            *(undefined4 *)(iVar8 + 0x1e8) = puVar9[2];
            *(undefined4 *)(iVar8 + 0x1ec) = *puVar9;
            *(undefined4 *)(iVar8 + 0x1f0) = puVar9[1];
            *(undefined4 *)(iVar8 + 500) = puVar9[2];
          }
          iVar8 = iVar8 + 0x3bc;
          bVar22 = pUVar17 != (UnwindMapEntry *)0x0;
          pUVar17 = (UnwindMapEntry *)((int)&pUVar17[-1].action + 3);
        } while (bVar22);
        pUVar17 = (UnwindMapEntry *)0xffffffff;
      }
    }
    else {
      piVar19 = (int *)(uint)((UnwindMapEntry *)param_1[2] != *(UnwindMapEntry **)(iVar8 + 0x45c));
      local_78 = piVar19;
      local_7c = *(UnwindMapEntry **)(iVar8 + 0x45c);
      local_9c = 0;
      local_98 = 0;
      local_94 = 0;
      local_93 = 0;
      local_92 = 0;
      local_8c = *param_1;
      local_88 = param_1[1] + -1;
      pUVar17 = (UnwindMapEntry *)&stack0xfffffffc;
      if (param_1[1] != 0) {
        piVar7 = (int *)(*param_1 + 4);
        pUVar17 = (UnwindMapEntry *)&stack0xfffffffc;
        do {
          if ((local_8c != *(int *)(piVar7[0x62] + 0x438)) && (piVar7[0xae] != 0)) {
            local_74 = piVar7[0xb1];
            local_80 = 0;
            iVar8 = (int)piVar19 + 1;
            local_a4 = (UnwindMapEntry *)(&DAT_00639270 + (int)piVar19 * 0x2c);
            do {
              iVar18 = local_80;
              if ((local_74 == local_a4->toState) &&
                 (cVar5 = *(char *)((int)&local_9c + local_80),
                 *(undefined1 *)((int)&local_9c + local_80) = 1, cVar5 == '\0')) {
                iVar18 = param_1[0x4e];
                iVar12 = 0x109999 - *(int *)(iVar18 + 0x1820);
                iVar21 = *(int *)(iVar18 + 0x1824) - (*(int *)(iVar18 + 0x1824) * iVar8) / 0xb;
                if ((*(uint *)(iVar18 + 0x19a0) & 1) != 1U - (int)local_7c) {
                  iVar21 = -iVar21;
                  iVar12 = -iVar12;
                }
                *piVar7 = iVar12;
                piVar7[1] = iVar21;
                piVar7[2] = 0;
                iVar18 = local_80;
                piVar19 = local_78;
              }
              local_a4 = (UnwindMapEntry *)((int)local_a4 + 4);
              iVar8 = iVar8 + 2;
              local_80 = iVar18 + 1;
            } while (iVar18 + 1 < 0xb);
            FUN_005ee2d0(*(int *)(param_1[0x4e] + 0x438) + 4,0xa0000);
            pUVar17 = local_7c;
            iVar8 = param_1[0x4e];
            iVar18 = *(int *)(iVar8 + 0x1820);
            if ((*(uint *)(iVar8 + 0x19a0) & 1) == 1U - (int)local_7c) {
              iVar18 = -iVar18;
            }
            uVar15 = *piVar7 - iVar18 >> 0x1f;
            if ((int)((*piVar7 - iVar18 ^ uVar15) - uVar15) < 0x10999a) {
              iVar18 = *(int *)(iVar8 + 0x1820) + -0x110000;
              if ((UnwindMapEntry *)(*(uint *)(iVar8 + 0x19a0) & 1) != local_7c) {
                iVar18 = -iVar18;
              }
              *piVar7 = iVar18;
            }
            puVar9 = (undefined4 *)FUN_00590ae0(&local_48,piVar7);
            uVar6 = FUN_005ee080(*puVar9,puVar9[1]);
            *(undefined2 *)(piVar7 + 0xc) = uVar6;
            *(undefined2 *)(piVar7 + 0x18) = uVar6;
          }
          piVar7 = piVar7 + 0xef;
          local_8c = local_8c + 0x3bc;
          bVar22 = local_88 != 0;
          local_88 = local_88 + -1;
        } while (bVar22);
      }
    }
    goto LAB_005b81d6;
  }
  pUVar17 = (UnwindMapEntry *)&stack0xfffffffc;
  if (iVar18 != 3) goto LAB_005b81d6;
  if (*(uint *)(iVar8 + 0x45c) == param_1[2]) {
    local_44 = param_1[1];
    iVar18 = *param_1;
    iVar21 = 0;
    pUVar17 = UnwindMapEntry_ARRAY_0063fff8 + 1;
    while (bVar22 = local_44 != 0, local_44 = local_44 + -1, bVar22) {
      if (((*(int *)(iVar18 + 700) != 0) && (iVar18 != *(int *)(*(int *)(iVar18 + 0x18c) + 0x438)))
         && (uVar15 = *(int *)(iVar18 + 4) - *(int *)(*(int *)(iVar8 + 0x438) + 4),
            uVar16 = (int)uVar15 >> 0x1f, pUVar10 = (UnwindMapEntry *)((uVar15 ^ uVar16) - uVar16),
            (int)pUVar10 < (int)pUVar17)) {
        pUVar17 = pUVar10;
        iVar21 = iVar18;
      }
      iVar18 = iVar18 + 0x3bc;
    }
    if (iVar21 != 0) {
      iVar18 = FUN_005ec250();
      *(int *)(iVar21 + 4) =
           (((int)(iVar18 * 0x32 + (iVar18 * 0x32 >> 0x1f & 0x7fffU)) >> 0xf) *
           (*(int *)(iVar21 + 4) - *(int *)(*(int *)(iVar8 + 0x438) + 4))) / 100 +
           *(int *)(*(int *)(iVar8 + 0x438) + 4);
      pUVar17 = (UnwindMapEntry *)param_1[0x4e];
      iVar8 = *(int *)(iVar21 + 8);
      iVar18 = FUN_005ec250();
      *(uint *)(iVar21 + 8) =
           (((int)(iVar18 * 0x32 + (iVar18 * 0x32 >> 0x1f & 0x7fffU)) >> 0xf) *
           (iVar8 - *(int *)(pUVar17[0x87].toState + 8))) / 100 +
           (((-1 < iVar8 - *(int *)(*(int *)(param_1[0x4e] + 0x438) + 8)) - 1 & 0xfffffffe) + 1) *
           0x70000 + *(int *)(pUVar17[0x87].toState + 8);
      iVar8 = *(int *)(param_1[0x4e] + 0x438);
      FUN_00590aa0(*(int *)(iVar21 + 4) - *(int *)(iVar8 + 4),
                   *(int *)(iVar21 + 8) - *(int *)(iVar8 + 8),
                   *(int *)(iVar21 + 0xc) - *(int *)(iVar8 + 0xc));
      uVar6 = FUN_005ee080(local_48,local_44);
      *(undefined2 *)(iVar8 + 0x34) = uVar6;
      *(undefined2 *)(iVar8 + 100) = uVar6;
    }
    goto LAB_005b81d6;
  }
  iVar18 = *(int *)(*(int *)(iVar8 + 0x438) + 4);
  iVar21 = *(int *)(iVar8 + 0x1820);
  if ((*(uint *)(iVar8 + 0x19a0) & 1) == param_1[2]) {
    iVar21 = -iVar21;
  }
  iVar8 = *(int *)(param_1[0x80] + 4);
  if (iVar21 < 0) {
    if (iVar8 < iVar18) {
LAB_005b81c4:
      iVar18 = iVar8;
    }
  }
  else if (iVar18 < iVar8) goto LAB_005b81c4;
  *(int *)(param_1[0x80] + 4) = iVar18;
  *(undefined4 *)(param_1[0x80] + 8) = 0;
  pUVar17 = (UnwindMapEntry *)&stack0xfffffffc;
LAB_005b81d6:
  iVar8 = param_1[0x4e];
  if (*(int *)(iVar8 + 0x448) != 5) {
    return;
  }
  iVar18 = *(int *)(iVar8 + 0x19cc);
  if (iVar18 != 0) {
    if (*(int *)(iVar8 + 0x45c) != param_1[2]) {
      local_3c[0] = 0;
      local_3c[1] = 0;
      local_3c[2] = 0;
      local_3c[3] = 0;
      local_3c[4] = 0;
      local_3c[5] = 0;
      iVar8 = *(int *)(iVar8 + 0x438);
      iVar21 = CONCAT22((short)((uint)pUVar17 >> 0x10),*(undefined2 *)(iVar8 + 0x34));
      local_3c[6] = 0xffffffff;
      local_3c[7] = 0xffffffff;
      local_3c[8] = 0xffffffff;
      local_3c[9] = 0xffffffff;
      local_3c[10] = 0xffffffff;
      local_3c[0xb] = 0xffffffff;
      local_3c[0xc] = 0xffffffff;
      piVar19 = (int *)FUN_005ee0f0(0x93333,iVar21);
      local_70 = *piVar19 + *(int *)(iVar8 + 4);
      local_78 = (int *)(iVar21 + 0x4000);
      local_6c = piVar19[1] + *(int *)(iVar8 + 8);
      local_68 = *(int *)(iVar8 + 0xc) + piVar19[2];
      local_9c = *param_1;
      local_98 = param_1[1] + -1;
      if (param_1[1] != 0) {
        piVar19 = (int *)(*param_1 + 8);
        do {
          if (piVar19[0xad] != 0) {
            iVar8 = piVar19[0xb0];
            if (iVar8 < 7) {
              local_a4 = (UnwindMapEntry *)0x0;
            }
            else if (((iVar8 == 7) || (iVar8 == 8)) ||
                    ((iVar8 == 10 ||
                     (((iVar8 == 0xb || (iVar8 == 0xf)) ||
                      (local_a4 = (UnwindMapEntry *)0x2, iVar8 == 0x12)))))) {
              local_a4 = (UnwindMapEntry *)0x1;
            }
            piVar7 = piVar19 + -1;
            FUN_005ee2d0(*(int *)(param_1[0x4e] + 0x438) + 4,0xa0000);
            iVar8 = param_1[0x4e];
            iVar21 = *piVar7;
            if (((iVar21 < *(int *)(iVar8 + 0x1828)) || (*(int *)(iVar8 + 0x1834) < iVar21)) ||
               (((*piVar19 < *(int *)(iVar8 + 0x182c) ||
                 ((*(int *)(iVar8 + 0x1838) < *piVar19 || (piVar19[1] < *(int *)(iVar8 + 0x1830)))))
                || (*(int *)(iVar8 + 0x183c) < piVar19[1])))) {
              bVar22 = false;
            }
            else {
              bVar22 = true;
            }
            if (!bVar22) {
              iVar8 = *(int *)(iVar8 + 0x438);
              iVar12 = *(int *)(iVar8 + 8);
              iVar4 = *(int *)(iVar8 + 0xc);
              *piVar7 = *piVar7 + (*(int *)(iVar8 + 4) - iVar21) * 2;
              *piVar19 = *piVar19 + (iVar12 - *piVar19) * 2;
              piVar19[1] = piVar19[1] + (iVar4 - piVar19[1]) * 2;
            }
            uVar6 = FUN_005ee080(*(int *)(param_1[0x4e] + 0x1614) - *piVar7,
                                 *(int *)(param_1[0x4e] + 0x1618) - *piVar19);
            *(undefined2 *)(piVar19 + 0xb) = uVar6;
            *(undefined2 *)(piVar19 + 0x17) = uVar6;
            iVar8 = 0;
            if (0 < iVar18) {
              do {
                if (local_3c[iVar8 + 6] < (int)local_a4) {
                  memmove(local_3c + iVar8 + 1,local_3c + iVar8,iVar8 * -4 + 0x18);
                  local_3c[iVar8] = local_9c;
                  local_3c[iVar8 + 6] = (int)local_a4;
                  iVar8 = 100;
                }
                iVar8 = iVar8 + 1;
              } while (iVar8 < iVar18);
            }
          }
          piVar19 = piVar19 + 0xef;
          bVar22 = local_98 != 0;
          local_9c = local_9c + 0x3bc;
          local_98 = local_98 + -1;
        } while (bVar22);
      }
      piVar19 = local_78;
      local_a4 = (UnwindMapEntry *)0x0;
      if (iVar18 < 1) {
        return;
      }
      piVar7 = local_3c;
      do {
        if (*piVar7 != 0) {
          FUN_005a5430(0x1c);
          piVar13 = piVar19;
          uVar11 = ftol(piVar19);
          piVar13 = (int *)FUN_005ee0f0(uVar11,piVar13);
          iVar8 = piVar13[1];
          iVar21 = piVar13[2];
          iVar12 = *piVar7;
          *(int *)(iVar12 + 4) = *piVar13 + local_70;
          *(int *)(iVar12 + 8) = iVar8 + local_6c;
          *(int *)(iVar12 + 0xc) = iVar21 + local_68;
          iVar8 = *piVar7;
          uVar6 = FUN_005ee080(*(int *)(param_1[0x4e] + 0x1614) - *(int *)(iVar8 + 4),
                               *(int *)(param_1[0x4e] + 0x1618) - *(int *)(iVar8 + 8));
          *(undefined2 *)(iVar8 + 0x34) = uVar6;
          *(undefined2 *)(iVar8 + 100) = uVar6;
        }
        local_a4 = (UnwindMapEntry *)((int)local_a4 + 1);
        piVar7 = piVar7 + 1;
      } while ((int)local_a4 < iVar18);
      return;
    }
    if (iVar18 != 0) {
      return;
    }
  }
  if (*(int *)(iVar8 + 0x45c) == param_1[2]) {
    iVar8 = param_1[1];
    if (iVar8 != 0) {
      piVar19 = (int *)(*param_1 + 4);
      do {
        iVar8 = iVar8 + -1;
        if ((((-1 < *piVar19) - 1 & 0xfffffffe) + 1 != ((-1 < piVar19[0xe8]) - 1 & 0xfffffffe) + 1)
           && (iVar18 = FUN_005b0b40(0), iVar18 < 2)) {
          *piVar19 = *(int *)(*(int *)(param_1[0x4e] + param_1[2] * -800 + 0x98c) + 4);
          FUN_005ee2d0(*(int *)(param_1[0x4e] + 0x438) + 4,0x93333);
        }
        piVar19 = piVar19 + 0xef;
      } while (iVar8 != 0);
    }
  }
  return;
}


