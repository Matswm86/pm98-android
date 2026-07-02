// FUN_005b31a0  entry=005b31a0  size=979 bytes

int __thiscall FUN_005b31a0(int param_1,int param_2)

{
  short sVar1;
  char cVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  uint uVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  int local_28;
  int local_24;
  int local_14;
  int local_8;
  
  local_28 = 0;
  local_24 = 0;
  local_14 = (*(int **)(param_1 + 0x184))[1];
  iVar10 = **(int **)(param_1 + 0x184);
  do {
    if (local_14 == 0) {
      if (local_28 < 0x71c) {
        local_24 = 0;
      }
      return local_24;
    }
    local_14 = local_14 + -1;
    if ((*(int *)(iVar10 + 700) != 0) && (iVar10 != param_1)) {
      if (param_1 == 0) {
        iVar5 = 0xc80000;
      }
      else {
        uVar3 = *(int *)(param_1 + 4) - *(int *)(param_1 + 0x3a4);
        uVar7 = (int)uVar3 >> 0x1f;
        iVar5 = (uVar3 ^ uVar7) - uVar7;
      }
      if (iVar10 == 0) {
        iVar4 = 0xc80000;
      }
      else {
        uVar3 = *(int *)(iVar10 + 4) - *(int *)(iVar10 + 0x3a4);
        uVar7 = (int)uVar3 >> 0x1f;
        iVar4 = (uVar3 ^ uVar7) - uVar7;
      }
      if (((iVar5 < iVar4 + 0x60000) || (cVar2 = FUN_005b3c10(100,300,900), cVar2 != '\0')) &&
         ((param_2 != 1 || (cVar2 = FUN_005b3580(iVar10 + 4), cVar2 == '\0')))) {
        if (param_2 == 2) {
          if (iVar10 == 0) {
            iVar5 = 0xc80000;
          }
          else {
            uVar3 = *(int *)(iVar10 + 4) - *(int *)(iVar10 + 0x3a4);
            uVar7 = (int)uVar3 >> 0x1f;
            iVar5 = (uVar3 ^ uVar7) - uVar7;
          }
          if (param_1 == 0) {
            iVar4 = 0xc80000;
          }
          else {
            uVar3 = *(int *)(param_1 + 4) - *(int *)(param_1 + 0x3a4);
            uVar7 = (int)uVar3 >> 0x1f;
            iVar4 = (uVar3 ^ uVar7) - uVar7;
          }
          if (iVar5 < iVar4 + -0x40000) goto LAB_005b3536;
        }
        if (param_2 == 3) {
          if (iVar10 == 0) {
            iVar5 = 0xc80000;
          }
          else {
            uVar3 = *(int *)(iVar10 + 4) - *(int *)(iVar10 + 0x3a4);
            uVar7 = (int)uVar3 >> 0x1f;
            iVar5 = (uVar3 ^ uVar7) - uVar7;
          }
          if (param_1 == 0) {
            iVar4 = 0xc80000;
          }
          else {
            uVar3 = *(int *)(param_1 + 4) - *(int *)(param_1 + 0x3a4);
            uVar7 = (int)uVar3 >> 0x1f;
            iVar4 = (uVar3 ^ uVar7) - uVar7;
          }
          if (iVar5 < iVar4 + 0x30000) goto LAB_005b3536;
        }
        if (iVar10 == 0) {
          iVar5 = 0xc80000;
        }
        else {
          iVar5 = *(int *)(param_1 + 0xe4 +
                          (*(int *)(iVar10 + 0x2c4) + *(int *)(iVar10 + 0x2b8) * 0xb) * 4);
        }
        if (0x40000 < iVar5) {
          if (iVar10 == 0) {
            iVar5 = 0xc80000;
          }
          else {
            iVar5 = *(int *)(param_1 + 0xe4 +
                            (*(int *)(iVar10 + 0x2c4) + *(int *)(iVar10 + 0x2b8) * 0xb) * 4);
          }
          iVar9 = 0x7c72;
          iVar8 = *(int *)(iVar10 + 0x2b8) * 0xb + *(int *)(iVar10 + 0x2c4);
          local_8 = (*(int **)(param_1 + 0x188))[1];
          iVar4 = **(int **)(param_1 + 0x188);
          sVar1 = *(short *)(param_1 + 0xb8 + iVar8 * 2);
          while (local_8 != 0) {
            local_8 = local_8 + -1;
            if (iVar4 == 0) {
              iVar6 = 0xc80000;
            }
            else {
              iVar6 = *(int *)(param_1 + 0xe4 +
                              (*(int *)(iVar4 + 0x2c4) + *(int *)(iVar4 + 0x2b8) * 0xb) * 4);
            }
            if (iVar6 < iVar5 + 0x18000) {
              if (iVar4 == 0) {
                iVar6 = 0xc80000;
              }
              else {
                iVar6 = *(int *)(param_1 + 0xe4 +
                                (*(int *)(iVar4 + 0x2c4) + *(int *)(iVar4 + 0x2b8) * 0xb) * 4);
              }
              if ((0x7ffff < iVar6) ||
                 (uVar3 = (uint)(short)(*(short *)(param_1 + 0xb8 +
                                                  (*(int *)(iVar4 + 0x2c4) +
                                                  *(int *)(iVar4 + 0x2b8) * 0xb) * 2) - sVar1),
                 uVar7 = (int)uVar3 >> 0x1f, iVar6 = (uVar3 ^ uVar7) - uVar7, iVar9 <= iVar6 / 2)) {
                if (iVar4 == 0) {
                  iVar6 = 0xc80000;
                }
                else {
                  iVar6 = *(int *)(param_1 + 0xe4 +
                                  (*(int *)(iVar4 + 0x2c4) + *(int *)(iVar4 + 0x2b8) * 0xb) * 4);
                }
                if ((iVar6 <= iVar5 + -0x80000) ||
                   (uVar3 = (uint)(short)(*(short *)(param_1 + 0xb8 +
                                                    (*(int *)(iVar4 + 0x2c4) +
                                                    *(int *)(iVar4 + 0x2b8) * 0xb) * 2) - sVar1),
                   uVar7 = (int)uVar3 >> 0x1f, iVar6 = (uVar3 ^ uVar7) - uVar7, iVar9 <= iVar6))
                goto LAB_005b348d;
              }
              iVar9 = iVar6;
            }
LAB_005b348d:
            iVar4 = iVar4 + 0x3bc;
          }
          if (iVar10 == 0) {
            iVar5 = 0xc80000;
          }
          else {
            iVar5 = *(int *)(param_1 + 0xe4 + iVar8 * 4);
          }
          uVar3 = (int)(iVar5 - 0x80000U) >> 0x1f;
          iVar5 = (iVar9 * 100) /
                  (((int)(((iVar5 - 0x80000U ^ uVar3) - uVar3) * 100) / 0x1e >> 0x10) + 100);
          if (sVar1 < 0x71c7) {
            if (0x471b < sVar1) {
              iVar5 = (iVar5 * 2) / 3;
            }
          }
          else {
            iVar5 = iVar5 / 2;
          }
          if (local_28 < iVar5) {
            local_28 = iVar5;
            local_24 = iVar10;
          }
        }
      }
    }
LAB_005b3536:
    iVar10 = iVar10 + 0x3bc;
  } while( true );
}


