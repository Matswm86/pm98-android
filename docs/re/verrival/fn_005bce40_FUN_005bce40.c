// FUN_005bce40  entry=005bce40  size=936 bytes

int __thiscall FUN_005bce40(int *param_1,int param_2)

{
  int *piVar1;
  bool bVar2;
  bool bVar3;
  bool bVar4;
  bool bVar5;
  LPMSG lpMsg;
  int iVar6;
  AFX_MODULE_STATE *pAVar7;
  BOOL BVar8;
  int iVar9;
  int iVar10;
  undefined4 *puVar11;
  int local_290;
  int local_28c;
  undefined4 uStack_284;
  tagPOINT tStack_280;
  tagPOINT local_278;
  undefined4 auStack_270 [18];
  undefined4 uStack_228;
  undefined4 local_204;
  CHAR local_200 [512];
  
  iVar10 = -1;
  bVar5 = false;
  bVar3 = true;
  if ((DAT_00674c64 != param_1) && (iVar9 = 0, param_1[0x95] == 0)) {
    if (DAT_00674e98 == (CWinThread *)0x0) {
      DAT_00674e98 = AfxGetThread();
    }
    lpMsg = (LPMSG)(DAT_00674e98 + 0x34);
    GetCursorPos(&local_278);
    local_290 = 1;
    param_1[0x95] = (int)DAT_00674c64;
    local_28c = 0;
    DAT_00674c64 = param_1;
    do {
      if ((param_2 != 0) && (param_2 <= local_28c)) break;
      bVar4 = bVar3;
      iVar10 = local_290;
      if (DAT_00674ea8 == 0) {
        if (((DAT_006658ec == '\0') &&
            (iVar6 = (**(code **)(*DAT_006749ac + 0x60))(DAT_006749ac), iVar6 < 0)) &&
           (iVar6 = (**(code **)(*DAT_006749ac + 0x6c))(DAT_006749ac), iVar6 < 0)) {
          puVar11 = auStack_270;
          for (iVar6 = 0x1b; iVar6 != 0; iVar6 = iVar6 + -1) {
            *puVar11 = 0;
            puVar11 = puVar11 + 1;
          }
          auStack_270[0] = 0x6c;
          uStack_228 = 0x20;
          piVar1 = *(int **)(DAT_00674800 + 0x18 + DAT_00674c2c * 0x134);
          (**(code **)(*piVar1 + 0x30))(piVar1,auStack_270);
          DAT_00674e9c = DAT_00674e9c + 1;
          if (0x19 < DAT_00674e9c) {
            uStack_284 = CONCAT31(uStack_284._1_3_,DAT_00674c3c);
            FUN_005c4250(0,uStack_284);
          }
        }
        else {
          DAT_00674e9c = 0;
        }
        if ((DAT_006658ec == '\0') && (DAT_00674e9c == 0)) {
          (**(code **)(*param_1 + 200))();
          for (piVar1 = DAT_00674bbc; piVar1 != (int *)0x0; piVar1 = (int *)piVar1[0x14]) {
            (**(code **)(*piVar1 + 0x110))();
          }
          FUN_005bcdd0();
          iVar6 = iVar9;
          if (-1 < iVar9) {
            iVar6 = iVar9 + 1;
            pAVar7 = AfxGetModuleState();
            iVar9 = (**(code **)(**(int **)(pAVar7 + 4) + 0x68))(iVar9);
            if (iVar9 == 0) {
              iVar6 = -1;
            }
          }
          GetCursorPos(&tStack_280);
          if ((tStack_280.x == local_278.x) && (tStack_280.y == local_278.y)) {
            bVar2 = false;
          }
          else {
            bVar2 = true;
          }
          iVar9 = iVar6;
          if (((bVar2) || (DAT_00674c60 == 0)) || (bVar4 = false, bVar3)) {
            local_278.x = tStack_280.x;
            local_278.y = tStack_280.y;
            if (DAT_006658f8 != '\0') {
              FUN_005be820(&tStack_280);
              FUN_005c2100(DAT_006dc4c0,tStack_280.x,tStack_280.y);
            }
          }
        }
      }
      else {
        DAT_00674ea8 = DAT_00674ea8 + -1;
      }
      while ((bVar3 = bVar4, iVar10 != 0 &&
             (BVar8 = PeekMessageA(lpMsg,(HWND)0x0,0,0,0), iVar6 = DAT_00674654, BVar8 != 0))) {
        for (; iVar6 != 0; iVar6 = iVar6 + -1) {
          FUN_005f51d0(lpMsg);
        }
        iVar9 = (**(code **)(*(int *)DAT_00674e98 + 100))();
        if (iVar9 == 0) {
          AfxPostQuitMessage(0);
LAB_005bd0f5:
          FUN_005bd200(0xffffffff);
        }
        else if ((char)param_1[0xfb] == '\0') {
          bVar5 = true;
          goto LAB_005bd0f5;
        }
        iVar9 = (**(code **)(*(int *)DAT_00674e98 + 0x6c))(lpMsg);
        iVar9 = (iVar9 != 0) - 1;
        iVar10 = iVar10 + -1;
        bVar4 = bVar3;
      }
      if (iVar10 == 0) {
        local_290 = local_290 + 1;
        if (0xc < local_290) {
          local_290 = 0xc;
        }
      }
      else if ((iVar10 == local_290) && (local_290 = local_290 + -1, local_290 < 1)) {
        local_290 = 1;
      }
      local_28c = local_28c + 1;
    } while (DAT_00674c64 == param_1);
    FUN_005bd200(0);
    iVar10 = param_1[0x16];
  }
  if (bVar5) {
    local_204 = 0xffff0003;
    lstrcpyA(local_200,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_204,(ThrowInfo *)&DAT_0063ac98);
  }
  if (iVar10 == -1) {
    uStack_284 = 0;
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&uStack_284,(ThrowInfo *)&DAT_0063ab88);
  }
  return iVar10;
}


