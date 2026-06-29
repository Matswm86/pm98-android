// FUN_0042c200  entry=0042c200  size=817 bytes

void FUN_0042c200(uint param_1)

{
  char cVar1;
  void *pvVar2;
  int iVar3;
  uint uVar4;
  uint uVar5;
  int *this;
  undefined4 *puVar6;
  int iVar7;
  uint *puVar8;
  undefined4 *puVar9;
  uint *lpString1;
  LPCSTR local_54;
  undefined4 local_50 [20];
  
  FUN_0044fb30(&DAT_00497480,0);
  DAT_00497484 = 0;
  FUN_0044fb30(&DAT_00497498,0);
  DAT_0049749c = 0;
  FUN_0044fb30(&DAT_00497488,0);
  DAT_0049748c = 0;
  FUN_0044fb30(&DAT_00497490,0);
  DAT_00497494 = 0;
  pvVar2 = (void *)FUN_00445a90(&DAT_00497e10,param_1);
  iVar3 = FUN_0043b680(pvVar2);
  puVar6 = *(undefined4 **)(iVar3 + 0x24);
  do {
    if (puVar6 == (undefined4 *)0x0) {
      param_1 = 1;
      if (1 < DAT_00497484) {
        iVar3 = 0x50;
        do {
          uVar4 = FUN_0042c540((void *)(DAT_00497480 + iVar3),DAT_00497480 + iVar3 + -0x50);
          if (uVar4 != 0) {
            iVar7 = param_1 - 1;
            local_54 = (LPCSTR)0x0;
            uVar4 = (int)param_1 / 2;
            if (-1 < iVar7) {
              do {
                this = (int *)(uVar4 * 0x50 + DAT_00497480);
                if (*this == *(int *)(DAT_00497480 + iVar3)) break;
                uVar5 = FUN_0042c540(this,DAT_00497480 + iVar3);
                if (uVar5 == 0) {
                  iVar7 = uVar4 - 1;
                }
                else {
                  local_54 = (LPCSTR)(uVar4 + 1);
                }
                uVar4 = (iVar7 + 1 + (int)local_54) / 2;
              } while ((int)local_54 <= iVar7);
            }
            if (uVar4 != param_1) {
              puVar6 = (undefined4 *)(DAT_00497480 + iVar3);
              puVar9 = local_50;
              for (iVar7 = 0x14; iVar7 != 0; iVar7 = iVar7 + -1) {
                *puVar9 = *puVar6;
                puVar6 = puVar6 + 1;
                puVar9 = puVar9 + 1;
              }
              memmove((void *)((uVar4 + 1) * 0x50 + DAT_00497480),
                      (void *)(DAT_00497480 + uVar4 * 0x50),iVar3 + uVar4 * -0x50);
              puVar6 = local_50;
              puVar9 = (undefined4 *)(DAT_00497480 + uVar4 * 0x50);
              for (iVar7 = 0x14; iVar7 != 0; iVar7 = iVar7 + -1) {
                *puVar9 = *puVar6;
                puVar6 = puVar6 + 1;
                puVar9 = puVar9 + 1;
              }
            }
          }
          param_1 = param_1 + 1;
          iVar3 = iVar3 + 0x50;
        } while ((int)param_1 < DAT_00497484);
      }
      FUN_0042ead0(&DAT_00497498);
      FUN_0042ead0(&DAT_00497488);
      FUN_0042ead0(&DAT_00497490);
      return;
    }
    if (*(char *)(puVar6 + 8) != 'b') {
      cVar1 = *(char *)((int)puVar6 + 0x16);
      uVar4 = (uint)(*(char *)(puVar6 + 0x13) == '\x03');
      if (cVar1 == '\0') {
        local_54 = (LPCSTR)*puVar6;
        iVar3 = DAT_00497484 + 1;
        iVar7 = iVar3 * 0x50;
        FUN_0044fb30(&DAT_00497480,iVar7);
        puVar8 = (uint *)(DAT_00497480 + -0x50 + iVar7);
        DAT_00497484 = iVar3;
        *puVar8 = (uint)*(ushort *)(puVar6 + 5);
        puVar8[1] = param_1;
        puVar8[2] = uVar4;
LAB_0042c3f4:
        lpString1 = puVar8 + 3;
      }
      else if (cVar1 == '\x01') {
        local_54 = (LPCSTR)*puVar6;
        iVar3 = DAT_0049749c + 1;
        iVar7 = iVar3 * 0x50;
        FUN_0044fb30(&DAT_00497498,iVar7);
        puVar8 = (uint *)(DAT_00497498 + -0x50 + iVar7);
        DAT_0049749c = iVar3;
        *puVar8 = (uint)*(ushort *)(puVar6 + 5);
        lpString1 = puVar8 + 3;
        puVar8[1] = param_1;
        puVar8[2] = uVar4;
      }
      else {
        if (cVar1 != '\x02') {
          if (cVar1 != '\x03') goto LAB_0042c406;
          local_54 = (LPCSTR)*puVar6;
          iVar3 = DAT_00497494 + 1;
          iVar7 = iVar3 * 0x50;
          FUN_0044fb30(&DAT_00497490,iVar7);
          puVar8 = (uint *)(DAT_00497490 + -0x50 + iVar7);
          DAT_00497494 = iVar3;
          *puVar8 = (uint)*(ushort *)(puVar6 + 5);
          puVar8[1] = param_1;
          puVar8[2] = uVar4;
          goto LAB_0042c3f4;
        }
        local_54 = (LPCSTR)*puVar6;
        iVar3 = DAT_0049748c + 1;
        iVar7 = iVar3 * 0x50;
        FUN_0044fb30(&DAT_00497488,iVar7);
        puVar8 = (uint *)(DAT_00497488 + -0x50 + iVar7);
        DAT_0049748c = iVar3;
        *puVar8 = (uint)*(ushort *)(puVar6 + 5);
        lpString1 = puVar8 + 3;
        puVar8[1] = param_1;
        puVar8[2] = uVar4;
      }
      lstrcpyA((LPSTR)lpString1,local_54);
      puVar8[0x13] = 0;
    }
LAB_0042c406:
    puVar6 = (undefined4 *)puVar6[0x15];
  } while( true );
}


