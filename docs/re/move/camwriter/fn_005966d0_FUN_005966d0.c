// FUN_005966d0  entry=005966d0  size=2650 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __thiscall FUN_005966d0(int param_1,uint param_2)

{
  LPSTR lpString1;
  code *pcVar1;
  byte bVar2;
  short sVar3;
  int iVar4;
  undefined4 uVar5;
  int iVar6;
  uint uVar7;
  undefined4 uVar8;
  
  if (*(int *)(param_1 + 0x454) != 0) {
    return;
  }
  iVar4 = *(int *)(param_1 + 0x1998);
  *(undefined4 *)(param_1 + 0x454) = 0x168;
  if (iVar4 == 0) {
    iVar4 = 0x157c;
  }
  *(int *)(param_1 + 0x1998) = iVar4;
  pcVar1 = lstrcpyA_exref;
  lpString1 = (LPSTR)(param_1 + 0x1840);
  lstrcpyA(lpString1,(&PTR_DAT_006640a0)[(((int)param_2 < 1) - 1 & param_2) + DAT_00674e78 * 0xf]);
  *(undefined4 *)(param_1 + 0x19d4) = 0xffffffff;
  *(undefined4 *)(param_1 + 0x19d8) = 0;
  *(undefined4 *)(param_1 + 0x434) = 0;
  *(undefined1 *)(param_1 + 0x1809) = 0;
  if (*(int *)(param_1 + 0x440) != 0) {
    FUN_00594470(6,*(int *)(param_1 + 0x440),2);
    uVar5 = FUN_005ec240();
    if (*(char *)(param_1 + 0x180b) != '\0') {
      FUN_004e9810();
    }
    FUN_005ec230(uVar5);
  }
  switch(param_2) {
  case 1:
    *(undefined4 *)(param_1 + 0x19d4) = 4;
    lstrcpyA(lpString1,(&PTR_s_TIEMPO_00664250)[DAT_00674e78 * 5 + *(int *)(param_1 + 0x19a0)]);
    if (*(int *)(param_1 + 0x19a0) != 4) {
      *(undefined1 *)(param_1 + 0x1809) = 1;
    }
    *(undefined4 *)(param_1 + 0x454) = 0x2d0;
    switch(*(int *)(param_1 + 0x19a0)) {
    case 0:
      FUN_00594470(0x1c,0,2);
      break;
    case 1:
      iVar4 = FUN_00450e60();
      if ((iVar4 != 0) ||
         ((*(int *)(*(int *)(param_1 + 0x468) + 0x44) == 0 &&
          (*(int *)(*(int *)(param_1 + 0x468) + 0x48) == 0)))) goto switchD_005967f9_caseD_4;
      FUN_00594470(0x1d,0,2);
      if (*(int *)(*(int *)(param_1 + 0x468) + 0x44) == 0) {
        FUN_00594470(0x1f,0,2);
      }
      break;
    case 2:
      FUN_00594470(0x1e,0,2);
      break;
    case 3:
      iVar4 = FUN_00450e60();
      if ((iVar4 != 0) || (*(int *)(*(int *)(param_1 + 0x468) + 0x48) == 0))
      goto switchD_005967f9_caseD_4;
      FUN_00594470(0x1f,0,2);
      break;
    case 4:
switchD_005967f9_caseD_4:
      param_2 = 10;
    }
    if (param_2 == 10) {
      FUN_005946d0();
      FUN_00594470(0x20,0,2);
    }
    break;
  case 2:
    *(undefined4 *)(param_1 + 0x19d4) = 5;
    if (*(int *)(param_1 + 0x440) == 0) {
      sVar3 = FUN_005ee080(*(undefined4 *)(param_1 + 0x1630),*(undefined4 *)(param_1 + 0x1634));
      iVar4 = FUN_005edfb0(*(undefined4 *)(param_1 + 0x1630),
                           *(undefined4 *)(&DAT_006d31c8 + (sVar3 + 8 >> 4 & 0xfffU) * 4),
                           *(undefined4 *)(param_1 + 0x1634),
                           *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar3 >> 4 & 0xfffU) * 4));
      if ((((double)iVar4 <= _DAT_006390d0) || (*(int *)(param_1 + 0x165c) == 0)) ||
         (iVar4 = FUN_005ec250(), (int)(iVar4 * 500 + (iVar4 * 500 >> 0x1f & 0x7fffU)) >> 0xf == 0))
      {
        uVar5 = FUN_005ec240();
        if (*(char *)(param_1 + 0x180b) != '\0') {
          FUN_004ec0b0();
        }
      }
      else {
        uVar5 = FUN_005ec240();
        if (*(char *)(param_1 + 0x180b) != '\0') {
          FUN_004eaeb0();
        }
      }
      FUN_005ec230(uVar5);
      FUN_00594470(0,0,0);
    }
    break;
  case 3:
    *(undefined4 *)(param_1 + 0x19d4) = 5;
    if (*(int *)(param_1 + 0x19a0) == 4) {
      *(undefined1 *)(param_1 + 0x1809) = 1;
      lstrcpyA(lpString1,&DAT_00666f70);
    }
    FUN_00594470(0,0,0);
    break;
  case 4:
    *(undefined4 *)(param_1 + 0x19d4) = 4;
    if (*(int *)(param_1 + 0x45c) == 0) {
      uVar5 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_004e7f60(*(undefined4 *)(param_1 + 0x480));
      }
    }
    else {
      uVar5 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_004e7f60(*(undefined4 *)(param_1 + 0x7a0));
      }
    }
    FUN_005ec230(uVar5);
    FUN_00594470(0xc,*(undefined4 *)(*(int *)(param_1 + 0x45c) * 800 + 0x46c + param_1),0);
    break;
  case 5:
    *(undefined4 *)(param_1 + 0x434) = *(undefined4 *)(param_1 + 0x43c);
    *(undefined4 *)(param_1 + 0x19d4) = 4;
    if (*(char *)(param_1 + 0x460) == '\0') {
      if (*(int *)(param_1 + 0x440) == 0) {
        if ((*(byte *)(param_1 + 0x461) & 8) == 0) {
          uVar5 = FUN_005ec240();
          if (*(char *)(param_1 + 0x180b) != '\0') {
            bVar2 = *(byte *)(param_1 + 0x461);
            if ((bVar2 & 2) == 0) {
              bVar2 = -((bVar2 & 4) != 0) & 3;
            }
            else {
              bVar2 = ((bVar2 & 4) != 0) + 1;
            }
            FUN_004e80a0(*(int *)(param_1 + 0x19cc) != 0,bVar2,*(undefined4 *)(param_1 + 0x19d0));
          }
        }
        else {
          uVar5 = FUN_005ec240();
          if (*(char *)(param_1 + 0x180b) != '\0') {
            bVar2 = *(byte *)(param_1 + 0x461);
            if ((bVar2 & 2) == 0) {
              bVar2 = -((bVar2 & 4) != 0) & 3;
            }
            else {
              bVar2 = ((bVar2 & 4) != 0) + 1;
            }
            FUN_004e82f0(*(int *)(param_1 + 0x19cc) != 0,bVar2,*(undefined4 *)(param_1 + 0x19d0));
          }
        }
      }
      else {
        uVar5 = FUN_005ec240();
        if (*(char *)(param_1 + 0x180b) != '\0') {
          bVar2 = *(byte *)(param_1 + 0x461);
          if ((bVar2 & 2) == 0) {
            bVar2 = -((bVar2 & 4) != 0) & 3;
          }
          else {
            bVar2 = ((bVar2 & 4) != 0) + 1;
          }
          FUN_004e8550(*(int *)(param_1 + 0x19cc) != 0,bVar2,*(undefined4 *)(param_1 + 0x19d0));
        }
      }
      FUN_005ec230(uVar5);
      bVar2 = *(byte *)(param_1 + 0x461);
      if (((bVar2 & 4) == 0) || ((bVar2 & 2) == 0)) {
        if ((bVar2 & 4) == 0) {
          if ((bVar2 & 2) == 0) {
            FUN_00594470(1,*(undefined4 *)(param_1 + 0x434),2);
          }
          else {
            *(undefined4 *)(param_1 + 0x19d4) = 1;
            lstrcpyA(lpString1,(&PTR_s_AMARILLA_00664208)[DAT_00674e78 * 3]);
            FUN_00594470(3,*(undefined4 *)(param_1 + 0x434),2);
          }
        }
        else {
          *(undefined4 *)(param_1 + 0x19d4) = 2;
          lstrcpyA(lpString1,(&PTR_DAT_0066420c)[DAT_00674e78 * 3]);
          FUN_00594470(4,*(undefined4 *)(param_1 + 0x434),2);
        }
      }
      else {
        *(undefined4 *)(param_1 + 0x19d4) = 3;
        lstrcpyA(lpString1,(&PTR_DAT_00664210)[DAT_00674e78 * 3]);
        FUN_00594470(5,*(undefined4 *)(param_1 + 0x434),2);
      }
    }
    else {
      lstrcpyA(lpString1,(&PTR_s_FUERA_DE_JUEGO_006640c0)[DAT_00674e78 * 0xf]);
      uVar5 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_004e7f70();
      }
      FUN_005ec230(uVar5);
      FUN_00594470(0xb,*(undefined4 *)(param_1 + 0x434),0);
    }
    break;
  case 6:
    FUN_00594470(8 - (uint)(*(int *)(*(int *)(param_1 + 0x444) + 0x2b8) != *(int *)(param_1 + 0x45c)
                           ),*(int *)(param_1 + 0x444),2);
    iVar4 = *(int *)(param_1 + 0x45c);
    iVar6 = param_1 + iVar4 * -800;
    uVar7 = *(uint *)(iVar6 + 0x798);
    uVar5 = CONCAT22((short)((uint)pcVar1 >> 0x10),*(undefined2 *)(*(int *)(iVar6 + 0x828) + 0x790))
    ;
    uVar7 = ((int)uVar7 <= *(int *)(param_1 + 0x478 + iVar4 * 800)) - 1 & uVar7;
    if ((*(int *)(*(int *)(param_1 + 0x468) + 0x14) == 0) || (uVar8 = 6, DAT_00674e7c == 8)) {
      uVar8 = 7;
    }
    *(undefined4 *)(param_1 + 0x19d4) = uVar8;
    if (*(int *)(param_1 + 0x19a0) == 4) {
      uVar8 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_004e9260();
      }
LAB_005970f4:
      FUN_005ec230(uVar8);
    }
    else if (*(int *)(*(int *)(param_1 + 0x444) + 0x2b8) != iVar4) {
      bVar2 = *(byte *)(param_1 + 0x462);
      if ((bVar2 & 4) == 0) {
        if (((*(byte *)(param_1 + 0x461) & 0x20) == 0) ||
           (iVar4 = FUN_005ec250(),
           499 < (int)(iVar4 * 1000 + (iVar4 * 1000 >> 0x1f & 0x7fffU)) >> 0xf)) {
          bVar2 = *(byte *)(param_1 + 0x462);
          if ((bVar2 & 2) == 0) {
            if ((bVar2 & 1) == 0) {
              uVar8 = FUN_005ec240();
              if (*(char *)(param_1 + 0x180b) != '\0') {
                FUN_004e9130(uVar5,uVar7,*(undefined1 *)(param_1 + 0x1674),
                             (*(byte *)(param_1 + 0x462) & 8) >> 3,0);
              }
            }
            else if ((bVar2 & 8) == 0) {
              if ((bVar2 & 0x60) == 0) {
                uVar8 = FUN_005ec240();
                if (*(char *)(param_1 + 0x180b) != '\0') {
                  FUN_004e8c70(uVar5,uVar7,*(undefined1 *)(param_1 + 0x1674),0);
                }
              }
              else {
                uVar8 = FUN_005ec240();
                if (*(char *)(param_1 + 0x180b) != '\0') {
                  FUN_004e8b40(uVar5,uVar7,*(undefined1 *)(param_1 + 0x1674),0);
                }
              }
            }
            else if ((bVar2 & 0x60) == 0) {
              uVar8 = FUN_005ec240();
              if (*(char *)(param_1 + 0x180b) != '\0') {
                FUN_004e8ed0(uVar5,uVar7,*(undefined1 *)(param_1 + 0x1674),0);
              }
            }
            else {
              uVar8 = FUN_005ec240();
              if (*(char *)(param_1 + 0x180b) != '\0') {
                FUN_004e8da0(uVar5,uVar7,*(undefined1 *)(param_1 + 0x1674),0);
              }
            }
          }
          else {
            uVar8 = FUN_005ec240();
            if (*(char *)(param_1 + 0x180b) != '\0') {
              FUN_004e9000(uVar5,uVar7,*(undefined1 *)(param_1 + 0x1674),0);
            }
          }
        }
        else {
          uVar8 = FUN_005ec240();
          if (*(char *)(param_1 + 0x180b) != '\0') {
            FUN_004e9390(uVar5,uVar7,*(undefined1 *)(param_1 + 0x1674),0);
          }
        }
      }
      else if ((bVar2 & 0x60) == 0) {
        if ((bVar2 & 0x80) == 0) {
          uVar8 = FUN_005ec240();
          if (*(char *)(param_1 + 0x180b) != '\0') {
            FUN_004e87b0(uVar5,uVar7,*(undefined1 *)(param_1 + 0x1674),0);
          }
        }
        else {
          uVar8 = FUN_005ec240();
          if (*(char *)(param_1 + 0x180b) != '\0') {
            FUN_004e88e0(uVar5,uVar7,*(undefined1 *)(param_1 + 0x1674),0);
          }
        }
      }
      else {
        uVar8 = FUN_005ec240();
        if (*(char *)(param_1 + 0x180b) != '\0') {
          FUN_004e8a10(uVar5,uVar7,*(undefined1 *)(param_1 + 0x1674),0);
        }
      }
      goto LAB_005970f4;
    }
    *(undefined1 *)(param_1 + 0x1809) = 1;
    *(undefined4 *)(param_1 + 0x434) = *(undefined4 *)(param_1 + 0x444);
    break;
  case 7:
    *(undefined4 *)(param_1 + 0x434) = *(undefined4 *)(param_1 + 0x43c);
    FUN_00594470(9,*(undefined4 *)(param_1 + 0x43c),2);
    bVar2 = *(byte *)(param_1 + 0x461);
    *(undefined4 *)(param_1 + 0x19d4) = 4;
    if (((bVar2 & 4) == 0) || ((bVar2 & 2) == 0)) {
      if ((bVar2 & 4) != 0) {
        uVar5 = *(undefined4 *)(param_1 + 0x434);
        *(undefined4 *)(param_1 + 0x19d4) = 2;
        uVar8 = 4;
        goto LAB_00596b17;
      }
      if ((bVar2 & 2) != 0) {
        uVar5 = *(undefined4 *)(param_1 + 0x434);
        *(undefined4 *)(param_1 + 0x19d4) = 1;
        uVar8 = 3;
        goto LAB_00596b17;
      }
    }
    else {
      uVar5 = *(undefined4 *)(param_1 + 0x434);
      *(undefined4 *)(param_1 + 0x19d4) = 3;
      uVar8 = 5;
LAB_00596b17:
      FUN_00594470(uVar8,uVar5,2);
    }
    uVar5 = FUN_005ec240();
    if (*(char *)(param_1 + 0x180b) != '\0') {
      FUN_004e9cd0();
    }
    FUN_005ec230(uVar5);
  }
  *(uint *)(param_1 + 0x1a38) = param_2;
  FUN_005942e0(8);
  return;
}


