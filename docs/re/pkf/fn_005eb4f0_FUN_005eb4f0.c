// FUN_005eb4f0  entry=005eb4f0  size=1446 bytes

undefined4 * __thiscall
FUN_005eb4f0(int *param_1,char *param_2,char *param_3,int param_4,char *param_5,size_t param_6)

{
  char cVar1;
  int iVar2;
  int iVar3;
  undefined4 uVar4;
  HLOCAL pvVar5;
  undefined1 *puVar6;
  char *pcVar7;
  uint uVar8;
  uint uVar9;
  int iVar10;
  void *pvVar11;
  char *pcVar12;
  char *pcVar13;
  int iVar14;
  undefined4 *local_11c;
  undefined4 *local_118;
  undefined4 local_110;
  char local_10c [128];
  char local_8c [128];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00621fde;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005e6370(param_2,param_3,local_8c,0x80);
  FUN_005f97e0(local_8c);
  local_11c = (undefined4 *)0x0;
  iVar2 = FUN_005e6300(0,local_8c,local_10c,0x80);
  do {
    if (iVar2 == 0) {
      ExceptionList = local_c;
      return (undefined4 *)0x0;
    }
    uVar8 = 0xffffffff;
    pcVar12 = &DAT_00665d78;
    do {
      pcVar7 = pcVar12;
      if (uVar8 == 0) break;
      uVar8 = uVar8 - 1;
      pcVar7 = pcVar12 + 1;
      cVar1 = *pcVar12;
      pcVar12 = pcVar7;
    } while (cVar1 != '\0');
    uVar8 = ~uVar8;
    iVar2 = -1;
    pcVar12 = local_10c;
    do {
      pcVar13 = pcVar12;
      if (iVar2 == 0) break;
      iVar2 = iVar2 + -1;
      pcVar13 = pcVar12 + 1;
      cVar1 = *pcVar12;
      pcVar12 = pcVar13;
    } while (cVar1 != '\0');
    pcVar12 = pcVar7 + -uVar8;
    pcVar7 = pcVar13 + -1;
    for (uVar9 = uVar8 >> 2; uVar9 != 0; uVar9 = uVar9 - 1) {
      *(undefined4 *)pcVar7 = *(undefined4 *)pcVar12;
      pcVar12 = pcVar12 + 4;
      pcVar7 = pcVar7 + 4;
    }
    for (uVar8 = uVar8 & 3; uVar8 != 0; uVar8 = uVar8 - 1) {
      *pcVar7 = *pcVar12;
      pcVar12 = pcVar12 + 1;
      pcVar7 = pcVar7 + 1;
    }
    iVar2 = _access(local_10c,0);
    if (iVar2 == 0) {
      iVar2 = param_1[3];
      iVar10 = 0;
      local_11c = (undefined4 *)0x0;
      if (iVar2 == 0) goto LAB_005eb6fd;
      uVar8 = iVar2 - iVar2 / 2;
      uVar9 = (int)uVar8 >> 0x1f;
      iVar14 = (uVar8 ^ uVar9) - uVar9;
      iVar10 = iVar2 / 2;
      break;
    }
    local_11c = (undefined4 *)((int)local_11c + 1);
    iVar2 = FUN_005e6300(local_11c,local_8c,local_10c,0x80);
  } while( true );
joined_r0x005eb628:
  if (iVar14 < 3) goto LAB_005eb684;
  iVar2 = _stricmp((char *)(*(int *)(param_1[6] + iVar10 * 4) + 4),local_10c);
  if (iVar2 < 0) {
    iVar14 = iVar14 / 2;
LAB_005eb670:
    iVar2 = iVar10 + iVar14;
  }
  else {
    iVar3 = _stricmp((char *)(*(int *)(param_1[6] + iVar10 * 4) + 4),local_10c);
    iVar2 = iVar10;
    if (0 < iVar3) {
      iVar14 = -(iVar14 / 2);
      goto LAB_005eb670;
    }
  }
  uVar8 = iVar10 - iVar2 >> 0x1f;
  iVar14 = (iVar10 - iVar2 ^ uVar8) - uVar8;
  iVar10 = iVar2;
  goto joined_r0x005eb628;
LAB_005eb684:
  iVar2 = _stricmp((char *)(*(int *)(param_1[6] + iVar10 * 4) + 4),local_10c);
  if (iVar2 < 0) {
    if (iVar10 < param_1[3]) {
      do {
        iVar2 = _stricmp((char *)(*(int *)(param_1[6] + iVar10 * 4) + 4),local_10c);
        if (-1 < iVar2) break;
        iVar10 = iVar10 + 1;
      } while (iVar10 < param_1[3]);
    }
  }
  else {
    iVar2 = _stricmp((char *)(*(int *)(param_1[6] + iVar10 * 4) + 4),local_10c);
    if (0 < iVar2) {
      while ((0 < iVar10 &&
             (iVar2 = _stricmp((char *)(*(int *)(param_1[6] + -4 + iVar10 * 4) + 4),local_10c),
             -1 < iVar2))) {
        iVar10 = iVar10 + -1;
      }
    }
  }
LAB_005eb6fd:
  if ((-1 < iVar10) && (iVar10 < param_1[3])) {
    iVar2 = _stricmp((char *)(*(int *)(param_1[6] + iVar10 * 4) + 4),local_10c);
    if ((iVar2 == 0) &&
       ((local_11c = *(undefined4 **)(param_1[6] + iVar10 * 4), param_4 != 0 &&
        (((byte)local_11c[0x37] & 2) != 2)))) {
      ExceptionList = local_c;
      return (undefined4 *)0x0;
    }
  }
  if (local_11c == (undefined4 *)0x0) {
    DAT_006dc4d0 = 0;
    local_110 = operator_new(0x1fc);
    local_4 = 0;
    if (local_110 == (void *)0x0) {
      local_118 = (undefined4 *)0x0;
    }
    else {
      local_118 = (undefined4 *)FUN_005e65e0();
    }
    local_4 = 0xffffffff;
    if (local_118 == (undefined4 *)0x0) {
      DAT_006dc4d0 = 4;
      (**(code **)(*param_1 + 4))(4,0,0,0);
      ExceptionList = local_c;
      return (undefined4 *)0x0;
    }
    uVar4 = 1;
    if (param_1[0xb] != 0) {
      uVar4 = 0x27;
    }
    iVar2 = FUN_005e6950(local_10c,uVar4,1);
    if (iVar2 == 0) {
      DAT_006dc4d0 = 9;
      (**(code **)(*param_1 + 4))(9,local_10c,0,0);
      (**(code **)*local_118)(1);
      ExceptionList = local_c;
      return (undefined4 *)0x0;
    }
    if (param_1[1] != 0) {
      if (param_1[1] < param_1[3]) {
        FUN_005eb400(1);
      }
      else {
        iVar2 = 0;
        if (0 < param_1[3]) {
          do {
            iVar10 = *(int *)(param_1[6] + iVar2 * 4);
            iVar14 = *(int *)(iVar10 + 0x1f8);
            if (iVar14 != 0) {
              *(int *)(iVar10 + 0x1f8) = iVar14 + -1;
            }
            iVar2 = iVar2 + 1;
          } while (iVar2 < param_1[3]);
        }
      }
      if ((uint)local_118[0x7e] < 0xfffffff0) {
        local_118[0x7e] = local_118[0x7e] + 3;
      }
    }
    iVar2 = param_1[3];
    pvVar11 = (void *)0x0;
    if (iVar2 != 0) {
      pvVar11 = (void *)(iVar2 / 2);
      uVar8 = iVar2 - (int)pvVar11 >> 0x1f;
      iVar2 = (iVar2 - (int)pvVar11 ^ uVar8) - uVar8;
      if (2 < iVar2) {
        do {
          local_110 = pvVar11;
          iVar10 = _stricmp((char *)(*(int *)(param_1[6] + (int)pvVar11 * 4) + 4),
                            (char *)(local_118 + 1));
          if (iVar10 < 0) {
            iVar2 = iVar2 / 2;
LAB_005eb8cd:
            pvVar11 = (void *)((int)pvVar11 + iVar2);
          }
          else {
            iVar10 = _stricmp((char *)(*(int *)(param_1[6] + (int)pvVar11 * 4) + 4),
                              (char *)(local_118 + 1));
            if (0 < iVar10) {
              iVar2 = -(iVar2 / 2);
              goto LAB_005eb8cd;
            }
          }
          uVar8 = (int)local_110 - (int)pvVar11 >> 0x1f;
          iVar2 = ((int)local_110 - (int)pvVar11 ^ uVar8) - uVar8;
        } while (2 < iVar2);
      }
      pcVar12 = (char *)(local_118 + 1);
      iVar2 = _stricmp((char *)(*(int *)(param_1[6] + (int)pvVar11 * 4) + 4),pcVar12);
      if (iVar2 < 0) {
        if ((int)pvVar11 < param_1[3]) {
          do {
            iVar2 = _stricmp((char *)(*(int *)(param_1[6] + (int)pvVar11 * 4) + 4),pcVar12);
            if (-1 < iVar2) break;
            pvVar11 = (void *)((int)pvVar11 + 1);
          } while ((int)pvVar11 < param_1[3]);
        }
      }
      else {
        iVar2 = _stricmp((char *)(*(int *)(param_1[6] + (int)pvVar11 * 4) + 4),pcVar12);
        if (0 < iVar2) {
          while ((0 < (int)pvVar11 &&
                 (iVar2 = _stricmp((char *)(*(int *)(param_1[6] + -4 + (int)pvVar11 * 4) + 4),
                                   pcVar12), -1 < iVar2))) {
            pvVar11 = (void *)((int)pvVar11 + -1);
          }
        }
      }
    }
    local_11c = local_118;
    if (-1 < (int)pvVar11) {
      if (param_1[4] <= param_1[3]) {
        iVar2 = param_1[5] + param_1[4];
        if (iVar2 <= param_1[3]) goto LAB_005eb9d1;
        if ((HLOCAL)param_1[6] == (HLOCAL)0x0) {
          pvVar5 = LocalAlloc(0x40,iVar2 * 4);
        }
        else {
          pvVar5 = LocalReAlloc((HLOCAL)param_1[6],iVar2 * 4,0x42);
        }
        param_1[6] = (int)pvVar5;
        if (pvVar5 == (HLOCAL)0x0) goto LAB_005eb9d1;
        local_110 = (void *)param_1[4];
        param_1[4] = iVar2;
      }
      for (iVar2 = param_1[3]; (int)pvVar11 < iVar2; iVar2 = iVar2 + -1) {
        *(undefined4 *)(param_1[6] + iVar2 * 4) = *(undefined4 *)(param_1[6] + -4 + iVar2 * 4);
      }
      if ((int)pvVar11 <= param_1[3]) {
        *(undefined4 **)(param_1[6] + (int)pvVar11 * 4) = local_118;
        param_1[3] = param_1[3] + 1;
      }
    }
  }
LAB_005eb9d1:
  if (param_5 == (char *)0x0) {
    ExceptionList = local_c;
    return local_11c;
  }
  if (param_6 == 0) {
    ExceptionList = local_c;
    return local_11c;
  }
  uVar8 = 0xffffffff;
  do {
    pcVar12 = param_3;
    if (uVar8 == 0) break;
    uVar8 = uVar8 - 1;
    pcVar12 = param_3 + 1;
    cVar1 = *param_3;
    param_3 = pcVar12;
  } while (cVar1 != '\0');
  uVar8 = ~uVar8;
  pcVar12 = pcVar12 + -uVar8;
  pcVar7 = local_8c;
  for (uVar9 = uVar8 >> 2; uVar9 != 0; uVar9 = uVar9 - 1) {
    *(undefined4 *)pcVar7 = *(undefined4 *)pcVar12;
    pcVar12 = pcVar12 + 4;
    pcVar7 = pcVar7 + 4;
  }
  for (uVar8 = uVar8 & 3; uVar8 != 0; uVar8 = uVar8 - 1) {
    *pcVar7 = *pcVar12;
    pcVar12 = pcVar12 + 1;
    pcVar7 = pcVar7 + 1;
  }
  _strupr(local_8c);
  uVar8 = 0xffffffff;
  do {
    if (uVar8 == 0) break;
    uVar8 = uVar8 - 1;
    cVar1 = *param_2;
    param_2 = param_2 + 1;
  } while (cVar1 != '\0');
  pcVar12 = local_10c + (~uVar8 - 1);
  puVar6 = (undefined1 *)FUN_005e6120(pcVar12,0,0);
  *puVar6 = 0;
  pcVar7 = strstr(local_8c,pcVar12);
  if (pcVar7 == (char *)0x0) {
    pcVar7 = local_8c;
  }
  else {
    uVar8 = 0xffffffff;
    do {
      if (uVar8 == 0) break;
      uVar8 = uVar8 - 1;
      cVar1 = *pcVar12;
      pcVar12 = pcVar12 + 1;
    } while (cVar1 != '\0');
    pcVar7 = pcVar7 + (~uVar8 - 1);
  }
  strncpy(param_5,pcVar7,param_6);
  param_5[param_6 - 1] = '\0';
  ExceptionList = local_c;
  return local_11c;
}


