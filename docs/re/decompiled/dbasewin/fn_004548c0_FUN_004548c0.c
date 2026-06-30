// FUN_004548c0  entry=004548c0  size=936 bytes

int __thiscall FUN_004548c0(void *this,int param_1)

{
  int *piVar1;
  bool bVar2;
  void *this_00;
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
  if ((DAT_00501dac != this) && (iVar9 = 0, *(int *)((int)this + 0x254) == 0)) {
    if (DAT_00501fe0 == (CWinThread *)0x0) {
      DAT_00501fe0 = AfxGetThread();
    }
    lpMsg = (LPMSG)(DAT_00501fe0 + 0x34);
    GetCursorPos(&local_278);
    local_290 = 1;
    *(void **)((int)this + 0x254) = DAT_00501dac;
    local_28c = 0;
    DAT_00501dac = this;
    do {
      if ((param_1 != 0) && (param_1 <= local_28c)) break;
      bVar4 = bVar3;
      iVar10 = local_290;
      if (DAT_00502020 == 0) {
        if (((DAT_004959b4 == '\0') &&
            (iVar6 = (**(code **)(*DAT_00501a14 + 0x60))(DAT_00501a14), iVar6 < 0)) &&
           (iVar6 = (**(code **)(*DAT_00501a14 + 0x6c))(DAT_00501a14), iVar6 < 0)) {
          puVar11 = auStack_270;
          for (iVar6 = 0x1b; iVar6 != 0; iVar6 = iVar6 + -1) {
            *puVar11 = 0;
            puVar11 = puVar11 + 1;
          }
          auStack_270[0] = 0x6c;
          uStack_228 = 0x20;
          piVar1 = *(int **)(DAT_00501788 + 0x18 + DAT_00501d74 * 0x134);
          (**(code **)(*piVar1 + 0x30))(piVar1,auStack_270);
          DAT_00501fe4 = DAT_00501fe4 + 1;
          if (0x19 < DAT_00501fe4) {
            uStack_284 = CONCAT31(uStack_284._1_3_,DAT_00501d84);
            FUN_00464880(DAT_00502018,0,DAT_00501d84);
          }
        }
        else {
          DAT_00501fe4 = 0;
        }
        if ((DAT_004959b4 == '\0') && (DAT_00501fe4 == 0)) {
          (**(code **)(*(int *)this + 200))();
          for (piVar1 = DAT_00501d04; piVar1 != (int *)0x0; piVar1 = (int *)piVar1[0x14]) {
            (**(code **)(*piVar1 + 0x110))();
          }
          FUN_00454850();
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
          if (((bVar2) || (DAT_00501da8 == 0)) || (bVar4 = false, bVar3)) {
            local_278.x = tStack_280.x;
            local_278.y = tStack_280.y;
            if (DAT_004959c0 != '\0') {
              FUN_004562a0(this,&tStack_280);
              FUN_00459ad0(this,DAT_0051a558,tStack_280.x,tStack_280.y);
            }
          }
        }
      }
      else {
        DAT_00502020 = DAT_00502020 + -1;
      }
      while ((bVar3 = bVar4, iVar10 != 0 &&
             (BVar8 = PeekMessageA(lpMsg,(HWND)0x0,0,0,0), this_00 = DAT_005015d8,
             iVar6 = DAT_005015dc, BVar8 != 0))) {
        for (; iVar6 != 0; iVar6 = iVar6 + -1) {
          FUN_00470ff0(this_00,(int)lpMsg);
          this_00 = (void *)((int)this_00 + 0x68);
        }
        iVar9 = (**(code **)(*(int *)DAT_00501fe0 + 100))();
        if (iVar9 == 0) {
          AfxPostQuitMessage(0);
LAB_00454b75:
          FUN_00454c80(this,0xffffffff);
        }
        else if (*(char *)((int)this + 0x3ec) == '\0') {
          bVar5 = true;
          goto LAB_00454b75;
        }
        iVar9 = (**(code **)(*(int *)DAT_00501fe0 + 0x6c))(lpMsg);
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
    } while (DAT_00501dac == this);
    FUN_00454c80(this,0);
    iVar10 = *(int *)((int)this + 0x58);
  }
  if (bVar5) {
    local_204 = 0xffff0003;
    lstrcpyA(local_200,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_204,(ThrowInfo *)&DAT_0048b400);
  }
  if (iVar10 == -1) {
    uStack_284 = 0;
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&uStack_284,(ThrowInfo *)&DAT_0048dd30);
  }
  return iVar10;
}


