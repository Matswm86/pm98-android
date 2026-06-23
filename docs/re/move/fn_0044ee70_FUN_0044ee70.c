// FUN_0044ee70  entry=0044ee70  size=5729 bytes

void __fastcall FUN_0044ee70(int *param_1)

{
  ushort uVar1;
  int *piVar2;
  int *piVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  int iVar7;
  void *pvVar8;
  uint uVar9;
  int *piVar10;
  int iVar11;
  undefined4 local_24c;
  CHAR local_248 [512];
  int local_48;
  int *local_44;
  undefined4 local_40;
  undefined4 local_3c;
  undefined4 local_38;
  undefined4 local_34;
  undefined4 local_30;
  int local_2c;
  void *local_28;
  int local_24;
  int *local_20;
  int *local_1c;
  void *local_18;
  undefined1 *local_14;
  void *local_10;
  undefined1 *puStack_c;
  undefined4 local_8;
  
  puStack_c = &LAB_00609ced;
  local_10 = ExceptionList;
  local_14 = &stack0xfffffda8;
  local_30 = 0;
  ExceptionList = &local_10;
  *param_1 = 0;
  param_1[3] = 0;
  local_8 = 1;
  DAT_0066afd8 = 0;
  DAT_0066afdc = (int *)0x0;
  local_1c = param_1;
  FUN_0044d5f0();
  param_1[0xf] = *(int *)(DAT_0066afd0 + 0xb4);
  param_1[0x10] = *(int *)(DAT_0066afd0 + 0xb8);
  if ((DAT_00652a10 != 0) && ((param_1[0x1fc] != 0 || (param_1[0x3e4] != 0)))) {
    DAT_0066afdc = (int *)0x0;
    FUN_0044cd10();
    iVar5 = DAT_006d2fd8;
    do {
      iVar4 = FUN_005e1620(0xffffffff);
    } while (iVar4 == 0);
    local_18 = (void *)CONCAT22(local_18._2_2_,*(undefined2 *)(iVar5 + 0x4c));
    FUN_005e1640();
    if ((DAT_00652a10 != 0) && (param_1[0x3e9] != 0)) {
      local_28 = operator_new(0x13b14);
      local_8._0_1_ = 2;
      if (local_28 == (void *)0x0) {
        local_20 = (int *)0x0;
      }
      else {
        local_20 = (int *)FUN_004ca0e0();
      }
      local_8 = CONCAT31(local_8._1_3_,1);
      if (local_20 == (int *)0x0) {
        local_24c = 0xffff0002;
        lstrcpyA(local_248,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_24c,(ThrowInfo *)&DAT_0063ac98);
      }
      iVar5 = FUN_004c8510(DAT_00674ea0);
      if (iVar5 != 0) {
        FUN_005bebc0(4);
        iVar5 = DAT_006d2fd8;
        do {
          iVar4 = FUN_005e1620(0xffffffff);
        } while (iVar4 == 0);
        *(undefined2 *)(iVar5 + 0x4c) = 0;
        if (*(int *)(iVar5 + 0x44) != 0) {
          FUN_005de570(0,3000);
        }
        FUN_005e1640();
        iVar5 = DAT_006d2fd8;
        do {
          do {
            iVar4 = FUN_005e1620(0xffffffff);
          } while (iVar4 == 0);
          iVar4 = 1;
          if (*(int *)(iVar5 + 0x44) != 0) {
            iVar4 = FUN_005de5e0();
          }
          FUN_005e1640();
          iVar5 = DAT_006d2fd8;
        } while (iVar4 == 0);
        do {
          iVar4 = FUN_005e1620(0xffffffff);
        } while (iVar4 == 0);
        if (*(int *)(iVar5 + 0x44) != 0) {
          FUN_005de510();
        }
        if (*(int *)(iVar5 + 0x44) != 0) {
          FUN_00451260(1);
        }
        *(undefined4 *)(iVar5 + 0x44) = 0;
        *(undefined4 *)(iVar5 + 0x48) = 0xffffffff;
        FUN_005e1640();
        iVar5 = DAT_006d2fd8;
        do {
          iVar4 = FUN_005e1620(0xffffffff);
        } while (iVar4 == 0);
        *(short *)(iVar5 + 0x4c) = (short)local_18;
        if (*(int *)(iVar5 + 0x44) != 0) {
          FUN_005de630(local_18);
        }
        FUN_005e1640();
        FUN_005bce40(0);
      }
      if (local_20 != (int *)0x0) {
        (**(code **)(*local_20 + 4))(1);
      }
    }
    iVar5 = DAT_006d2fd8;
    if (local_1c[1000] != 5) {
      uVar9 = 0x3bb;
      *local_1c = 0;
      iVar5 = DAT_006d2fd8;
      local_24 = 0;
      local_2c = 0;
      local_44 = (int *)0x0;
      local_20 = (int *)0x0;
      do {
        iVar4 = FUN_005e1620(0xffffffff);
      } while (iVar4 == 0);
      uVar1 = *(ushort *)(iVar5 + 0x4c);
      FUN_005e1640();
      iVar5 = DAT_006d2fd8;
      local_28 = (void *)(uint)uVar1;
      do {
        iVar4 = FUN_005e1620(0xffffffff);
      } while (iVar4 == 0);
      *(undefined2 *)(iVar5 + 0x4c) = 0;
      if (*(int *)(iVar5 + 0x44) != 0) {
        FUN_005de570(0,2000);
      }
      FUN_005e1640();
      iVar5 = DAT_006d2fd8;
      do {
        do {
          iVar4 = FUN_005e1620(0xffffffff);
        } while (iVar4 == 0);
        iVar4 = 1;
        if (*(int *)(iVar5 + 0x44) != 0) {
          iVar4 = FUN_005de5e0();
        }
        FUN_005e1640();
        iVar5 = DAT_006d2fd8;
      } while (iVar4 == 0);
      do {
        iVar4 = FUN_005e1620(0xffffffff);
      } while (iVar4 == 0);
      if (*(int *)(iVar5 + 0x44) != 0) {
        FUN_005de510();
      }
      if (*(int *)(iVar5 + 0x44) != 0) {
        FUN_00451260(1);
      }
      *(undefined4 *)(iVar5 + 0x44) = 0;
      *(undefined4 *)(iVar5 + 0x48) = 0xffffffff;
      FUN_005e1640();
      local_48 = DAT_006d2fd8;
      DAT_006d2fd8 = 0;
      local_18 = operator_new(0xb8);
      local_8._0_1_ = 3;
      if (local_18 == (void *)0x0) {
        iVar5 = 0;
      }
      else {
        iVar5 = FUN_004e7ae0();
      }
      piVar3 = local_1c;
      local_8 = CONCAT31(local_8._1_3_,1);
      if (iVar5 == 0) {
        local_24c = 0xffff0002;
        lstrcpyA(local_248,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_24c,(ThrowInfo *)&DAT_0063ac98);
      }
      local_1c[1] = iVar5;
      (**(code **)(*DAT_0066b1e0 + 0x124))(iVar5,0,0);
      FUN_00606220();
      *(undefined4 *)(piVar3[1] + 0xb0) = 1;
      DAT_0066afdc = piVar3 + 1000;
      piVar3[3] = 1;
      DAT_0066afd8 = 1;
      if ((*DAT_0066afdc == 2) || (*DAT_0066afdc == 3)) {
        piVar3[0x3fd] = 1;
        local_18 = (void *)DAT_0066afdc[0x14];
      }
      else {
        local_18 = (void *)0x0;
      }
      FUN_00590fc0(piVar3);
      piVar10 = local_44;
      do {
        if ((int *)*piVar3 == (int *)0x0) {
          iVar5 = FUN_004f9940(0x3bb,0,0);
          *piVar3 = iVar5;
LAB_0044f2dd:
          if (piVar10 != (int *)0x0) goto LAB_0044f2e1;
          piVar2 = (int *)*piVar3;
          if (piVar2 == (int *)0x0) {
            uVar9 = 0x396;
          }
          else {
            if ((char)piVar2[0xfb] == '\0') {
              (**(code **)(*piVar2 + 0x118))(DAT_00674ea0,0,0);
            }
            piVar2 = local_20;
            if (local_20 == (int *)0x0) {
              (**(code **)(*(int *)*piVar3 + 0x11c))();
            }
            uVar9 = FUN_005bce40(piVar2);
            local_2c = *(int *)(*piVar3 + 0x54);
          }
        }
        else {
          if (piVar10 == (int *)0x0) {
            if (uVar9 != 0x3bb) {
              (**(code **)(*(int *)*piVar3 + 0xc4))();
              FUN_0044e440();
              if (uVar9 == 0x3af) {
                iVar5 = local_2c + 1;
              }
              else {
                iVar5 = 1;
              }
              piVar10 = (int *)FUN_004f9940(uVar9,local_24,iVar5);
            }
            goto LAB_0044f2dd;
          }
LAB_0044f2e1:
          (**(code **)(*piVar10 + 0x11c))();
          uVar9 = FUN_005bce40(0);
          (**(code **)(*piVar10 + 4))(1);
          piVar10 = (int *)0x0;
          FUN_0044d5f0();
        }
        if (uVar9 < 0x397) {
          if (uVar9 != 0x396) {
            if (uVar9 == 0) {
              uVar9 = FUN_005910a0();
              local_20 = (int *)(uVar9 & 0xff);
              if (local_18 != (void *)0x0) {
                if (*(int *)(piVar3[1] + 0xb0) != 0) {
                  FUN_005e2a30(10,0);
                }
                local_18 = (void *)0x0;
              }
              if (piVar3[2] == 0) {
                uVar9 = 0x3bb;
                if (local_20 == (int *)0x0) {
                  FUN_00538950(1);
                }
              }
              else {
                uVar9 = 0x396;
              }
            }
            else {
              if (uVar9 != 1) goto LAB_0044f462;
              FUN_005910b0();
              uVar9 = (-(uint)(piVar3[2] != 0) & 0xffffffdb) + 0x3bb;
            }
          }
        }
        else if (uVar9 < 0x3ad) {
          if ((uVar9 == 0x3ac) || ((0x39a < uVar9 && (uVar9 < 0x39d)))) {
LAB_0044f42b:
            if (local_20 == (int *)0x0) {
              FUN_00585ee0((short)piVar3[local_2c * 0x1e8 + 0x1fa]);
              local_24 = FUN_005793d0();
              goto LAB_0044f467;
            }
          }
LAB_0044f462:
          uVar9 = 0x3bb;
        }
        else {
          if (uVar9 == 0x3af) goto LAB_0044f42b;
          if (uVar9 != 0x4e3e) goto LAB_0044f462;
          piVar3[2] = 1;
          uVar9 = 0x396;
        }
LAB_0044f467:
      } while (uVar9 != 0x396);
      pvVar8 = (void *)piVar3[1];
      if (pvVar8 != (void *)0x0) {
        thunk_FUN_005e1900();
        operator_delete(pvVar8);
      }
      piVar3[1] = 0;
      if ((int *)*piVar3 != (int *)0x0) {
        (**(code **)(*(int *)*piVar3 + 4))(1);
      }
      iVar5 = local_48;
      *piVar3 = 0;
      piVar3[3] = 0;
      DAT_0066afd8 = 0;
      DAT_0066afdc = (int *)0x0;
      DAT_006d2fd8 = local_48;
      do {
        iVar4 = FUN_005e1620(0xffffffff);
      } while (iVar4 == 0);
      *(short *)(iVar5 + 0x4c) = (short)local_28;
      if (*(int *)(iVar5 + 0x44) != 0) {
        FUN_005de570(local_28,1000);
      }
      FUN_005e1640();
      if (piVar3[2] != 0) {
        local_24c = 0x4e3e;
        lstrcpyA(local_248,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_24c,(ThrowInfo *)&DAT_0063ac98);
      }
      FUN_005e1140(1,0,0,0,1);
      FUN_0044d520();
      goto LAB_0044f520;
    }
    do {
      iVar4 = FUN_005e1620(0xffffffff);
    } while (iVar4 == 0);
    *(short *)(iVar5 + 0x4c) = (short)local_18;
    if (*(int *)(iVar5 + 0x44) != 0) {
      FUN_005de630(local_18);
    }
    FUN_005e1640();
    iVar5 = DAT_006d2fd8;
    do {
      iVar4 = FUN_005e1620(0xffffffff);
    } while (iVar4 == 0);
    if (*(int *)(iVar5 + 0x44) == 0) {
      iVar5 = 0;
    }
    else {
      iVar5 = FUN_005dddb0();
    }
    FUN_005e1640();
    if (iVar5 == 0) {
      FUN_005e1140(1,0,0,0,1);
    }
  }
  DAT_0066afdc = local_1c + 1000;
  local_18 = (void *)0x0;
  local_1c[3] = 0;
  DAT_0066afd8 = 1;
  for (; (int)local_18 < 1; local_18 = (void *)((int)local_18 + 1)) {
    uVar9 = rand();
    if (((((uVar9 & 1) != 0) && (uVar9 = rand(), (uVar9 & 1) != 0)) &&
        (uVar9 = rand(), (uVar9 & 1) != 0)) && (uVar9 = rand(), (uVar9 & 1) != 0)) {
      uVar9 = rand();
      iVar5 = rand();
      iVar5 = (int)(iVar5 * 0xb + (iVar5 * 0xb >> 0x1f & 0x7fffU)) >> 0xf;
      if (iVar5 == 0) {
        local_28 = (void *)CONCAT31(local_28._1_3_,
                                    *(undefined1 *)((uVar9 & 1) * 0x7a0 + 0xbb + (int)local_1c));
        iVar4 = rand();
        if ((int)((uint)local_28 & 0xff) <=
            (int)(iVar4 * 100 + (iVar4 * 100 >> 0x1f & 0x7fffU)) >> 0xf) goto LAB_0044f69f;
      }
      iVar4 = rand();
      FUN_0044ec00(uVar9 & 1,iVar5,
                   ((int)(iVar4 * 0x2d + (iVar4 * 0x2d >> 0x1f & 0x7fffU)) >> 0xf) + 1);
    }
LAB_0044f69f:
  }
  for (local_18 = (void *)0x0; (int)local_18 < 2; local_18 = (void *)((int)local_18 + 1)) {
    uVar9 = rand();
    if ((uVar9 & 1) != 0) {
      uVar9 = rand();
      iVar5 = rand();
      iVar5 = (int)(iVar5 * 0xb + (iVar5 * 0xb >> 0x1f & 0x7fffU)) >> 0xf;
      if (iVar5 == 0) {
        local_28 = (void *)CONCAT31(local_28._1_3_,
                                    *(undefined1 *)((uVar9 & 1) * 0x7a0 + 0xbb + (int)local_1c));
        iVar4 = rand();
        if ((int)((uint)local_28 & 0xff) <=
            (int)(iVar4 * 100 + (iVar4 * 100 >> 0x1f & 0x7fffU)) >> 0xf) goto LAB_0044f73a;
      }
      iVar4 = rand();
      FUN_0044ea40(uVar9 & 1,iVar5,
                   ((int)(iVar4 * 0x2d + (iVar4 * 0x2d >> 0x1f & 0x7fffU)) >> 0xf) + 1);
    }
LAB_0044f73a:
  }
  iVar4 = 0;
  iVar5 = 0;
  local_20 = (int *)0x0;
  local_2c = 0;
  local_24 = 0;
  local_18 = (void *)0x0;
  for (iVar7 = 0; iVar7 < 0xb; iVar7 = iVar7 + 1) {
    if ((short)local_1c[iVar7 * 0x2b + 0x22] != 0) {
      iVar5 = iVar5 + (uint)*(byte *)((int)local_1c + iVar7 * 0xac + 0xbf);
      local_24 = local_24 + 1;
      local_2c = iVar5;
    }
    if ((short)local_1c[iVar7 * 0x2b + 0x20a] != 0) {
      iVar4 = iVar4 + (uint)*(byte *)((int)local_1c + iVar7 * 0xac + 0x85f);
      local_18 = (void *)((int)local_18 + 1);
      local_20 = (int *)iVar4;
    }
  }
  if (0 < local_24) {
    iVar5 = iVar5 / local_24;
    local_2c = iVar5;
  }
  if (0 < (int)local_18) {
    iVar4 = iVar4 / (int)local_18;
    local_20 = (int *)iVar4;
  }
  iVar7 = rand();
  iVar4 = (((int)(iVar7 * 8 + (iVar7 * 8 >> 0x1f & 0x7fffU)) >> 0xf) - iVar4) + -1 + iVar5;
  if (iVar4 < 0) {
    iVar7 = rand();
    iVar4 = iVar4 + ((int)(iVar5 * iVar7 + (iVar5 * iVar7 >> 0x1f & 0x7fffU)) >> 0xf);
  }
  iVar5 = rand();
  if (3 - ((int)(iVar5 * 3 + (iVar5 * 3 >> 0x1f & 0x7fffU)) >> 0xf) < iVar4) {
    iVar5 = rand();
    iVar4 = 3 - ((int)(iVar5 * 3 + (iVar5 * 3 >> 0x1f & 0x7fffU)) >> 0xf);
  }
  for (iVar5 = 0; iVar5 < iVar4; iVar5 = iVar5 + 1) {
    iVar7 = rand();
    FUN_0044ece0(0,0,((int)(iVar7 * 0x2d + (iVar7 * 0x2d >> 0x1f & 0x7fffU)) >> 0xf) + 1);
  }
  iVar5 = rand();
  piVar3 = local_20;
  iVar5 = (((int)(iVar5 * 8 + (iVar5 * 8 >> 0x1f & 0x7fffU)) >> 0xf) - local_2c) + -1 +
          (int)local_20;
  if (iVar5 < 0) {
    iVar4 = rand();
    iVar5 = iVar5 + ((int)((int)piVar3 * iVar4 + ((int)piVar3 * iVar4 >> 0x1f & 0x7fffU)) >> 0xf);
  }
  iVar4 = rand();
  if (3 - ((int)(iVar4 * 3 + (iVar4 * 3 >> 0x1f & 0x7fffU)) >> 0xf) < iVar5) {
    iVar5 = rand();
    iVar5 = 3 - ((int)(iVar5 * 3 + (iVar5 * 3 >> 0x1f & 0x7fffU)) >> 0xf);
  }
  for (local_24 = 0; local_24 < iVar5; local_24 = local_24 + 1) {
    iVar4 = rand();
    FUN_0044ece0(1,0,((int)(iVar4 * 0x2d + (iVar4 * 0x2d >> 0x1f & 0x7fffU)) >> 0xf) + 1);
  }
  FUN_00450510(0x2d,0,0);
  FUN_0044d0d0();
  for (local_18 = (void *)0x0; (int)local_18 < 1; local_18 = (void *)((int)local_18 + 1)) {
    uVar9 = rand();
    if ((((uVar9 & 1) != 0) && (uVar9 = rand(), (uVar9 & 1) != 0)) &&
       ((uVar9 = rand(), (uVar9 & 1) != 0 && (uVar9 = rand(), (uVar9 & 1) != 0)))) {
      uVar9 = rand();
      iVar5 = rand();
      iVar5 = (int)(iVar5 * 0xb + (iVar5 * 0xb >> 0x1f & 0x7fffU)) >> 0xf;
      if (iVar5 == 0) {
        local_28 = (void *)CONCAT31(local_28._1_3_,
                                    *(undefined1 *)((uVar9 & 1) * 0x7a0 + 0xbb + (int)local_1c));
        iVar4 = rand();
        if ((int)((uint)local_28 & 0xff) <=
            (int)(iVar4 * 100 + (iVar4 * 100 >> 0x1f & 0x7fffU)) >> 0xf) goto LAB_0044f9c9;
      }
      iVar4 = rand();
      FUN_0044ec00(uVar9 & 1,iVar5,
                   ((int)(iVar4 * 0x2d + (iVar4 * 0x2d >> 0x1f & 0x7fffU)) >> 0xf) + 0x2e);
    }
LAB_0044f9c9:
  }
  for (local_18 = (void *)0x0; (int)local_18 < 2; local_18 = (void *)((int)local_18 + 1)) {
    uVar9 = rand();
    if ((uVar9 & 1) != 0) {
      uVar9 = rand();
      iVar5 = rand();
      iVar5 = (int)(iVar5 * 0xb + (iVar5 * 0xb >> 0x1f & 0x7fffU)) >> 0xf;
      if (iVar5 == 0) {
        local_28 = (void *)CONCAT31(local_28._1_3_,
                                    *(undefined1 *)((uVar9 & 1) * 0x7a0 + 0xbb + (int)local_1c));
        iVar4 = rand();
        if ((int)((uint)local_28 & 0xff) <=
            (int)(iVar4 * 100 + (iVar4 * 100 >> 0x1f & 0x7fffU)) >> 0xf) goto LAB_0044fa66;
      }
      iVar4 = rand();
      FUN_0044ea40(uVar9 & 1,iVar5,
                   ((int)(iVar4 * 0x2d + (iVar4 * 0x2d >> 0x1f & 0x7fffU)) >> 0xf) + 0x2e);
    }
LAB_0044fa66:
  }
  iVar4 = 0;
  local_2c = 0;
  local_18 = (void *)0x0;
  local_20 = (int *)0x0;
  for (iVar5 = 0; iVar5 < 0xb; iVar5 = iVar5 + 1) {
    if ((short)local_1c[iVar5 * 0x2b + 0x22] != 0) {
      local_2c = local_2c + (uint)*(byte *)((int)local_1c + iVar5 * 0xac + 0xbf);
      local_18 = (void *)((int)local_18 + 1);
    }
    if ((short)local_1c[iVar5 * 0x2b + 0x20a] != 0) {
      iVar4 = iVar4 + (uint)*(byte *)((int)local_1c + iVar5 * 0xac + 0x85f);
      local_20 = (int *)((int)local_20 + 1);
    }
  }
  local_2c = local_2c / (int)local_18;
  local_20 = (int *)(iVar4 / (int)local_20);
  iVar5 = rand();
  iVar4 = local_2c;
  iVar5 = (((int)(iVar5 * 8 + (iVar5 * 8 >> 0x1f & 0x7fffU)) >> 0xf) - (int)local_20) + -1 +
          local_2c;
  if (iVar5 < 0) {
    iVar7 = rand();
    iVar5 = iVar5 + ((int)(iVar4 * iVar7 + (iVar4 * iVar7 >> 0x1f & 0x7fffU)) >> 0xf);
  }
  iVar4 = rand();
  if (3 - ((int)(iVar4 * 3 + (iVar4 * 3 >> 0x1f & 0x7fffU)) >> 0xf) < iVar5) {
    iVar5 = rand();
    iVar5 = 3 - ((int)(iVar5 * 3 + (iVar5 * 3 >> 0x1f & 0x7fffU)) >> 0xf);
  }
  for (local_24 = 0; local_24 < iVar5; local_24 = local_24 + 1) {
    iVar4 = rand();
    FUN_0044ece0(0,1,((int)(iVar4 * 0x2d + (iVar4 * 0x2d >> 0x1f & 0x7fffU)) >> 0xf) + 1);
  }
  iVar5 = rand();
  piVar3 = local_20;
  iVar5 = (((int)(iVar5 * 8 + (iVar5 * 8 >> 0x1f & 0x7fffU)) >> 0xf) - local_2c) + -1 +
          (int)local_20;
  if (iVar5 < 0) {
    iVar4 = rand();
    iVar5 = iVar5 + ((int)((int)piVar3 * iVar4 + ((int)piVar3 * iVar4 >> 0x1f & 0x7fffU)) >> 0xf);
  }
  iVar4 = rand();
  if (3 - ((int)(iVar4 * 3 + (iVar4 * 3 >> 0x1f & 0x7fffU)) >> 0xf) < iVar5) {
    iVar5 = rand();
    iVar5 = 3 - ((int)(iVar5 * 3 + (iVar5 * 3 >> 0x1f & 0x7fffU)) >> 0xf);
  }
  for (iVar4 = 0; piVar3 = local_1c, iVar4 < iVar5; iVar4 = iVar4 + 1) {
    iVar7 = rand();
    FUN_0044ece0(1,1,((int)(iVar7 * 0x2d + (iVar7 * 0x2d >> 0x1f & 0x7fffU)) >> 0xf) + 1);
  }
  FUN_00450510(0x2d,0,0);
  iVar5 = FUN_00450e60();
  if (iVar5 == 0) {
    if (piVar3[0x11] != 0) {
      FUN_0044d190();
      goto LAB_0044fc43;
    }
  }
  else {
LAB_0044fc43:
    if ((piVar3[0x11] != 0) && (iVar5 = FUN_00450e60(), iVar5 == 0)) {
      for (local_18 = (void *)0x0; (int)local_18 < 1; local_18 = (void *)((int)local_18 + 1)) {
        uVar9 = rand();
        if (((((uVar9 & 1) != 0) && (uVar9 = rand(), (uVar9 & 1) != 0)) &&
            (uVar9 = rand(), (uVar9 & 1) != 0)) && (uVar9 = rand(), (uVar9 & 1) != 0)) {
          uVar9 = rand();
          iVar5 = rand();
          iVar5 = (int)(iVar5 * 0xb + (iVar5 * 0xb >> 0x1f & 0x7fffU)) >> 0xf;
          if (iVar5 == 0) {
            local_28 = (void *)CONCAT31(local_28._1_3_,
                                        *(undefined1 *)((uVar9 & 1) * 0x7a0 + 0xbb + (int)local_1c))
            ;
            iVar4 = rand();
            if ((int)((uint)local_28 & 0xff) <=
                (int)(iVar4 * 100 + (iVar4 * 100 >> 0x1f & 0x7fffU)) >> 0xf) goto LAB_0044fd13;
          }
          iVar4 = rand();
          FUN_0044ec00(uVar9 & 1,iVar5,
                       ((int)(iVar4 * 0xf + (iVar4 * 0xf >> 0x1f & 0x7fffU)) >> 0xf) + 0x5b);
        }
LAB_0044fd13:
      }
      for (local_18 = (void *)0x0; (int)local_18 < 2; local_18 = (void *)((int)local_18 + 1)) {
        uVar9 = rand();
        if ((uVar9 & 1) != 0) {
          uVar9 = rand();
          iVar5 = rand();
          iVar5 = (int)(iVar5 * 0xb + (iVar5 * 0xb >> 0x1f & 0x7fffU)) >> 0xf;
          if (iVar5 == 0) {
            local_28 = (void *)CONCAT31(local_28._1_3_,
                                        *(undefined1 *)((uVar9 & 1) * 0x7a0 + 0xbb + (int)local_1c))
            ;
            iVar4 = rand();
            if ((int)((uint)local_28 & 0xff) <=
                (int)(iVar4 * 100 + (iVar4 * 100 >> 0x1f & 0x7fffU)) >> 0xf) goto LAB_0044fdb0;
          }
          iVar4 = rand();
          FUN_0044ea40(uVar9 & 1,iVar5,
                       ((int)(iVar4 * 0xf + (iVar4 * 0xf >> 0x1f & 0x7fffU)) >> 0xf) + 0x5b);
        }
LAB_0044fdb0:
      }
      local_2c = 0;
      iVar5 = 0;
      local_18 = (void *)0x0;
      local_20 = (int *)0x0;
      for (iVar4 = 0; iVar4 < 0xb; iVar4 = iVar4 + 1) {
        if ((short)local_1c[iVar4 * 0x2b + 0x22] != 0) {
          local_2c = local_2c + (uint)*(byte *)((int)local_1c + iVar4 * 0xac + 0xbf);
          local_18 = (void *)((int)local_18 + 1);
        }
        if ((short)local_1c[iVar4 * 0x2b + 0x20a] != 0) {
          iVar5 = iVar5 + (uint)*(byte *)((int)local_1c + iVar4 * 0xac + 0x85f);
          local_20 = (int *)((int)local_20 + 1);
        }
      }
      local_2c = local_2c / (int)local_18;
      iVar5 = iVar5 / (int)local_20;
      iVar4 = rand();
      local_18 = (void *)((local_2c - iVar5) / 6 + -1 +
                         ((int)(iVar4 * 3 + (iVar4 * 3 >> 0x1f & 0x7fffU)) >> 0xf));
      if ((int)local_18 < 0) {
        iVar4 = rand();
        iVar4 = (local_2c / 0x14) * iVar4;
        local_18 = (void *)((int)local_18 + ((int)(iVar4 + (iVar4 >> 0x1f & 0x7fffU)) >> 0xf));
      }
      local_24 = 0;
      while ((local_24 < (int)local_18 / 2 ||
             (iVar4 = rand(), (int)(iVar4 * 4 + (iVar4 * 4 >> 0x1f & 0x7fffU)) >> 0xf == 0))) {
        iVar4 = rand();
        FUN_0044ece0(0,2,((int)(iVar4 * 0xf + (iVar4 * 0xf >> 0x1f & 0x7fffU)) >> 0xf) + 1);
        local_24 = local_24 + 1;
      }
      iVar4 = rand();
      iVar4 = (iVar5 - local_2c) / 6 + -1 +
              ((int)(iVar4 * 3 + (iVar4 * 3 >> 0x1f & 0x7fffU)) >> 0xf);
      if (iVar4 < 0) {
        iVar7 = rand();
        iVar7 = (iVar5 / 0x14) * iVar7;
        iVar4 = iVar4 + ((int)(iVar7 + (iVar7 >> 0x1f & 0x7fffU)) >> 0xf);
      }
      iVar5 = 0;
      while ((iVar5 < iVar4 / 2 ||
             (iVar7 = rand(), (int)(iVar7 * 4 + (iVar7 * 4 >> 0x1f & 0x7fffU)) >> 0xf == 0))) {
        iVar7 = rand();
        FUN_0044ece0(1,2,((int)(iVar7 * 0xf + (iVar7 * 0xf >> 0x1f & 0x7fffU)) >> 0xf) + 1);
        iVar5 = iVar5 + 1;
      }
      FUN_00450510(0xf,0,0);
      FUN_0044d250();
      for (local_18 = (void *)0x0; (int)local_18 < 1; local_18 = (void *)((int)local_18 + 1)) {
        uVar9 = rand();
        if (((((uVar9 & 1) != 0) && (uVar9 = rand(), (uVar9 & 1) != 0)) &&
            (uVar9 = rand(), (uVar9 & 1) != 0)) && (uVar9 = rand(), (uVar9 & 1) != 0)) {
          uVar9 = rand();
          iVar5 = rand();
          iVar5 = (int)(iVar5 * 0xb + (iVar5 * 0xb >> 0x1f & 0x7fffU)) >> 0xf;
          if (iVar5 == 0) {
            local_28 = (void *)CONCAT31(local_28._1_3_,
                                        *(undefined1 *)((uVar9 & 1) * 0x7a0 + 0xbb + (int)local_1c))
            ;
            iVar4 = rand();
            if ((int)((uint)local_28 & 0xff) <=
                (int)(iVar4 * 100 + (iVar4 * 100 >> 0x1f & 0x7fffU)) >> 0xf) goto LAB_00450005;
          }
          iVar4 = rand();
          FUN_0044ec00(uVar9 & 1,iVar5,
                       ((int)(iVar4 * 0xf + (iVar4 * 0xf >> 0x1f & 0x7fffU)) >> 0xf) + 0x6a);
        }
LAB_00450005:
      }
      for (local_18 = (void *)0x0; (int)local_18 < 2; local_18 = (void *)((int)local_18 + 1)) {
        uVar9 = rand();
        if ((uVar9 & 1) != 0) {
          uVar9 = rand();
          iVar5 = rand();
          iVar5 = (int)(iVar5 * 0xb + (iVar5 * 0xb >> 0x1f & 0x7fffU)) >> 0xf;
          if (iVar5 == 0) {
            local_28 = (void *)CONCAT31(local_28._1_3_,
                                        *(undefined1 *)((uVar9 & 1) * 0x7a0 + 0xbb + (int)local_1c))
            ;
            iVar4 = rand();
            if ((int)((uint)local_28 & 0xff) <=
                (int)(iVar4 * 100 + (iVar4 * 100 >> 0x1f & 0x7fffU)) >> 0xf) goto LAB_004500a2;
          }
          iVar4 = rand();
          FUN_0044ea40(uVar9 & 1,iVar5,
                       ((int)(iVar4 * 0xf + (iVar4 * 0xf >> 0x1f & 0x7fffU)) >> 0xf) + 0x6a);
        }
LAB_004500a2:
      }
      iVar4 = 0;
      iVar5 = 0;
      local_18 = (void *)0x0;
      iVar11 = 0;
      for (iVar7 = 0; iVar7 < 0xb; iVar7 = iVar7 + 1) {
        if ((short)local_1c[iVar7 * 0x2b + 0x22] != 0) {
          iVar5 = iVar5 + (uint)*(byte *)((int)local_1c + iVar7 * 0xac + 0xbf);
          local_18 = (void *)((int)local_18 + 1);
        }
        if ((short)local_1c[iVar7 * 0x2b + 0x20a] != 0) {
          iVar4 = iVar4 + (uint)*(byte *)((int)local_1c + iVar7 * 0xac + 0x85f);
          iVar11 = iVar11 + 1;
        }
      }
      iVar5 = iVar5 / (int)local_18;
      iVar4 = iVar4 / iVar11;
      iVar7 = rand();
      iVar7 = (iVar5 - iVar4) / 6 + -1 + ((int)(iVar7 * 3 + (iVar7 * 3 >> 0x1f & 0x7fffU)) >> 0xf);
      if (iVar7 < 0) {
        iVar11 = rand();
        iVar11 = (iVar5 / 0x14) * iVar11;
        iVar7 = iVar7 + ((int)(iVar11 + (iVar11 >> 0x1f & 0x7fffU)) >> 0xf);
      }
      local_24 = 0;
      while ((local_24 < iVar7 / 2 ||
             (iVar11 = rand(), (int)(iVar11 * 4 + (iVar11 * 4 >> 0x1f & 0x7fffU)) >> 0xf == 0))) {
        iVar11 = rand();
        FUN_0044ece0(0,3,((int)(iVar11 * 0xf + (iVar11 * 0xf >> 0x1f & 0x7fffU)) >> 0xf) + 1);
        local_24 = local_24 + 1;
      }
      iVar7 = rand();
      iVar5 = (iVar4 - iVar5) / 6 + -1 + ((int)(iVar7 * 3 + (iVar7 * 3 >> 0x1f & 0x7fffU)) >> 0xf);
      if (iVar5 < 0) {
        iVar7 = rand();
        iVar7 = (iVar4 / 0x14) * iVar7;
        iVar5 = iVar5 + ((int)(iVar7 + (iVar7 >> 0x1f & 0x7fffU)) >> 0xf);
      }
      iVar4 = 0;
      while ((iVar4 < iVar5 / 2 ||
             (iVar7 = rand(), (int)(iVar7 * 4 + (iVar7 * 4 >> 0x1f & 0x7fffU)) >> 0xf == 0))) {
        iVar7 = rand();
        FUN_0044ece0(1,3,((int)(iVar7 * 0xf + (iVar7 * 0xf >> 0x1f & 0x7fffU)) >> 0xf) + 1);
        iVar4 = iVar4 + 1;
      }
      FUN_00450510(0xf,0,0);
      local_1c[8] = 1;
      iVar5 = FUN_00450e60();
      if ((iVar5 == 0) && (local_1c[0x12] != 0)) {
        FUN_0044d310();
      }
    }
  }
  if ((local_1c[0x12] != 0) && (iVar5 = FUN_00450e60(), iVar5 == 0)) {
    iVar5 = rand();
    iVar4 = rand();
    pvVar8 = (void *)((int)(iVar4 * 6 + (iVar4 * 6 >> 0x1f & 0x7fffU)) >> 0xf);
    for (iVar5 = (int)(iVar5 * 6 + (iVar5 * 6 >> 0x1f & 0x7fffU)) >> 0xf; local_18 = pvVar8,
        (void *)iVar5 == pvVar8; iVar5 = iVar5 + (uVar9 & 1)) {
      uVar9 = rand();
      uVar6 = rand();
      pvVar8 = (void *)((int)pvVar8 + (uVar6 & 1));
    }
    local_20 = (int *)0x0;
    piVar3 = local_20;
    while (local_20 = piVar3, piVar3 = local_20, (int)local_20 < iVar5) {
      local_40 = 0;
      local_3c = 0;
      local_38 = 0;
      local_34 = 0;
      iVar4 = rand();
      if ((short)local_1c[((int)(iVar4 * 0xb + (iVar4 * 0xb >> 0x1f & 0x7fffU)) >> 0xf) * 0x2b +
                          0x22] != 0) {
        local_34 = CONCAT22((short)local_1c[((int)(iVar4 * 0xb + (iVar4 * 0xb >> 0x1f & 0x7fffU)) >>
                                            0xf) * 0x2b + 0x22],(short)local_1c[0x1fa]);
        FUN_004510b0(4,0,0,local_34);
        pvVar8 = local_18;
        piVar3 = (int *)((int)local_20 + 1);
      }
    }
    iVar5 = 0;
    while (iVar5 < (int)pvVar8) {
      local_40 = 0;
      local_3c = 0;
      local_38 = 0;
      local_34 = 0;
      iVar4 = rand();
      if ((short)local_1c[((int)(iVar4 * 0xb + (iVar4 * 0xb >> 0x1f & 0x7fffU)) >> 0xf) * 0x2b +
                          0x20a] != 0) {
        local_34 = CONCAT22((short)local_1c[((int)(iVar4 * 0xb + (iVar4 * 0xb >> 0x1f & 0x7fffU)) >>
                                            0xf) * 0x2b + 0x20a],(short)local_1c[0x3e2]);
        FUN_004510b0(4,0,0,local_34);
        iVar5 = iVar5 + 1;
        pvVar8 = local_18;
      }
    }
    local_1c[9] = 1;
    FUN_00606220();
  }
  local_1c[7] = 1;
  FUN_0044d520();
  local_1c[3] = 0;
  DAT_0066afd8 = 0;
  DAT_0066afdc = (int *)0x0;
LAB_0044f520:
  local_8 = 0xffffffff;
  FUN_00591080();
  ExceptionList = local_10;
  return;
}


