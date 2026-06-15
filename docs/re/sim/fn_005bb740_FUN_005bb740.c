// FUN_005bb740  entry=005bb740  size=1622 bytes
// callers/callees expanded one level from seeds

void FUN_005bb740(int *param_1,int *param_2,int *param_3,int param_4,int param_5,int param_6,
                 char param_7)

{
  int iVar1;
  int *piVar2;
  bool bVar3;
  byte bVar4;
  byte bVar5;
  byte bVar6;
  int iVar7;
  int iVar8;
  uint uVar9;
  uint uVar10;
  uint *puVar11;
  byte bVar12;
  uint uVar14;
  int iVar15;
  int iVar16;
  int local_48;
  int local_44;
  uint *local_40;
  int local_38;
  uint *local_24;
  int local_20;
  int local_1c [3];
  undefined4 local_10;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  uint uVar13;
  
  puStack_8 = &LAB_00620e10;
  local_c = ExceptionList;
  local_1c[0] = 0;
  local_1c[1] = 0;
  local_4 = 0;
  ExceptionList = &local_c;
  FUN_005bbf10(local_1c,0x10000);
  local_1c[1] = 0x10000;
  local_4 = 1;
  FUN_005bbda0();
  bVar12 = -1 << (8U - param_7 & 0x1f);
  uVar13 = (uint)bVar12;
  local_4 = CONCAT31(local_4._1_3_,3);
  if (*param_3 == 0) {
    FUN_005cb2b0();
  }
  iVar1 = param_3[7];
  iVar15 = 0;
  if (0 < param_1[1]) {
    do {
      if (**(int **)(*param_1 + iVar15 * 4) == 0) {
        FUN_005cb2b0();
      }
      iVar15 = iVar15 + 1;
    } while (iVar15 < param_1[1]);
  }
  local_48 = 0;
  if (0 < param_1[1]) {
    do {
      piVar2 = *(int **)(*param_1 + local_48 * 4);
      iVar15 = piVar2[7];
      iVar8 = *(int *)(*param_2 + local_48 * 4);
      local_40 = (uint *)0x0;
      if (0 < piVar2[6]) {
        local_44 = 0;
        _param_7 = 0;
        do {
          iVar16 = 0;
          if (0 < piVar2[5]) {
            do {
              uVar10 = (uint)(*(byte *)(iVar16 + *param_3 + _param_7) & bVar12);
              uVar9 = *(uint *)(iVar8 + (uint)*(byte *)(*piVar2 + iVar16 + local_44) * 4);
              uVar14 = uVar9 & 0xffffff;
              uVar9 = (uint)CONCAT12((char)((ulonglong)(uVar10 * (uVar14 >> 0x10)) /
                                           (ulonglong)(longlong)(int)uVar13),
                                     CONCAT11((char)((ulonglong)(uVar10 * (uVar14 >> 8 & 0xff)) /
                                                    (ulonglong)(longlong)(int)uVar13),
                                              (char)((ulonglong)(uVar10 * (uVar9 & 0xff)) /
                                                    (ulonglong)(longlong)(int)uVar13)));
              iVar7 = 0;
              puVar11 = local_24;
              if (0 < local_20) {
                do {
                  if (*puVar11 == uVar9) {
                    local_24[iVar7 * 2 + 1] = local_24[iVar7 * 2 + 1] + 1;
                    break;
                  }
                  iVar7 = iVar7 + 1;
                  puVar11 = puVar11 + 2;
                } while (iVar7 < local_20);
              }
              if (iVar7 == local_20) {
                local_10 = 1;
                local_1c[2] = uVar9;
                FUN_005bbdd0(local_20 + 1);
                FUN_005bbdb0(local_1c + 2);
              }
              iVar16 = iVar16 + 1;
            } while (iVar16 < piVar2[5]);
          }
          _param_7 = _param_7 + iVar1;
          local_40 = (uint *)((int)local_40 + 1);
          local_44 = local_44 + iVar15;
        } while ((int)local_40 < piVar2[6]);
      }
      local_48 = local_48 + 1;
    } while (local_48 < param_1[1]);
  }
  _param_7 = 1;
  if (1 < local_20) {
    do {
      uVar9 = local_24[_param_7 * 2 + 1];
      if ((int)local_24[_param_7 * 2 + -1] < (int)uVar9) {
        iVar15 = _param_7 + -1;
        local_40 = (uint *)0x0;
        iVar8 = (int)_param_7 / 2;
        if (-1 < iVar15) {
          do {
            if (local_24[iVar8 * 2 + 1] == uVar9) break;
            if ((int)uVar9 < (int)local_24[iVar8 * 2 + 1]) {
              local_40 = (uint *)(iVar8 + 1);
            }
            else {
              iVar15 = iVar8 + -1;
            }
            iVar8 = (iVar15 + 1 + (int)local_40) / 2;
          } while ((int)local_40 <= iVar15);
        }
        if (iVar8 != _param_7) {
          uVar9 = local_24[_param_7 * 2 + 1];
          uVar10 = local_24[_param_7 * 2];
          memmove(local_24 + iVar8 * 2 + 2,local_24 + iVar8 * 2,(iVar8 * 0x1fffffff + _param_7) * 8)
          ;
          local_24[iVar8 * 2] = uVar10;
          local_24[iVar8 * 2 + 1] = uVar9;
        }
      }
      _param_7 = _param_7 + 1;
    } while ((int)_param_7 < local_20);
  }
  iVar15 = 0;
  _param_7 = 0;
  if (0 < local_20) {
    iVar8 = param_6 + param_5;
    local_40 = (uint *)(param_4 + param_5 * 4);
    do {
      if (iVar8 <= param_5) break;
      _param_7 = FUN_005db6b0(local_24[iVar15 * 2],param_4,0x100,_param_7);
      if (param_6 < local_20 - iVar15) {
        uVar9 = *(uint *)(param_4 + _param_7 * 4);
        uVar10 = uVar9 & 0xffffff;
        uVar9 = (uint)(byte)local_24[iVar15 * 2] - (uVar9 & 0xff);
        uVar14 = (int)uVar9 >> 0x1f;
        if ((((int)((uVar9 ^ uVar14) - uVar14) < 4) &&
            (uVar9 = (uint)*(byte *)((int)local_24 + iVar15 * 8 + 1) - (uVar10 >> 8 & 0xff),
            uVar14 = (int)uVar9 >> 0x1f, (int)((uVar9 ^ uVar14) - uVar14) < 4)) &&
           (uVar9 = (uint)*(byte *)((int)local_24 + iVar15 * 8 + 2) - (uVar10 >> 0x10),
           uVar10 = (int)uVar9 >> 0x1f, (int)((uVar9 ^ uVar10) - uVar10) < 4)) {
          bVar3 = true;
        }
        else {
          bVar3 = false;
        }
        if (!bVar3) goto LAB_005bbb28;
      }
      else {
LAB_005bbb28:
        *local_40 = local_24[iVar15 * 2];
        param_5 = param_5 + 1;
        param_6 = param_6 + -1;
        local_40 = local_40 + 1;
      }
      iVar15 = iVar15 + 1;
    } while (iVar15 < local_20);
  }
  local_48 = 0;
  if (0 < param_1[1]) {
    do {
      piVar2 = *(int **)(*param_1 + local_48 * 4);
      iVar15 = piVar2[7];
      iVar8 = *(int *)(*param_2 + local_48 * 4);
      local_40 = (uint *)0x0;
      if (0 < piVar2[6]) {
        local_38 = 0;
        local_44 = 0;
        do {
          param_5 = 0;
          param_6 = local_38;
          if (0 < piVar2[5]) {
            do {
              uVar14 = (uint)(*(byte *)(param_5 + *param_3 + local_44) & bVar12);
              uVar9 = *(uint *)(iVar8 + (uint)*(byte *)(*piVar2 + param_6) * 4);
              uVar10 = uVar9 & 0xffffff;
              bVar4 = (byte)((ulonglong)(uVar14 * (uVar9 & 0xff)) / (ulonglong)(longlong)(int)uVar13
                            );
              bVar5 = (byte)((ulonglong)(uVar14 * (uVar10 >> 8 & 0xff)) /
                            (ulonglong)(longlong)(int)uVar13);
              bVar6 = (byte)((ulonglong)(uVar14 * (uVar10 >> 0x10)) /
                            (ulonglong)(longlong)(int)uVar13);
              uVar9 = ((bVar4 & 0xf8) << 5 | bVar5 & 0xfc) << 3 | (uint)(bVar6 >> 3);
              if ((uVar9 == 0) || (*(char *)(uVar9 + local_1c[0]) != '\0')) {
                _param_7 = (uint)*(byte *)(uVar9 + local_1c[0]);
              }
              else {
                _param_7 = FUN_005db6b0((uint)CONCAT12(bVar6,CONCAT11(bVar5,bVar4)),param_4,0x100,
                                        _param_7);
                *(char *)(uVar9 + local_1c[0]) = (char)_param_7;
              }
              *(char *)(*piVar2 + param_6) = (char)_param_7;
              param_5 = param_5 + 1;
              param_6 = param_6 + 1;
            } while (param_5 < piVar2[5]);
          }
          local_44 = local_44 + iVar1;
          local_40 = (uint *)((int)local_40 + 1);
          local_38 = local_38 + iVar15;
        } while ((int)local_40 < piVar2[6]);
      }
      if ((*piVar2 != 0) || (piVar2[0x10] != 0)) {
        FUN_005cb320();
      }
      local_48 = local_48 + 1;
    } while (local_48 < param_1[1]);
  }
  if ((*param_3 != 0) || (param_3[0x10] != 0)) {
    FUN_005cb320();
  }
  local_4 = CONCAT31(local_4._1_3_,1);
  for (; local_20 != 0; local_20 = local_20 + -1) {
  }
  if (local_24 != (uint *)0x0) {
    FUN_005bbed0(local_24);
  }
  local_4 = 0xffffffff;
  if (local_1c[0] != 0) {
    FUN_005bbed0(local_1c[0]);
  }
  ExceptionList = local_c;
  return;
}


