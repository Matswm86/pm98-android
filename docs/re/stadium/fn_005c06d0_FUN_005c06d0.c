// FUN_005c06d0  entry=005c06d0  size=1646 bytes
// callers/callees expanded one level from seeds

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __thiscall
FUN_005c06d0(int param_1,LPCSTR param_2,int param_3,ushort param_4,undefined2 param_5,int param_6)

{
  undefined1 *puVar1;
  int *piVar2;
  int iVar3;
  char cVar4;
  LPSTR pCVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  void *pvVar9;
  LPCSTR lpString2;
  char *lpString2_00;
  int local_c58;
  CHAR local_c4c [16];
  undefined1 local_c3c;
  undefined4 local_b34;
  undefined4 local_b30;
  undefined4 local_b2c;
  uint local_b28;
  CHAR local_b24 [260];
  undefined4 local_a20;
  undefined4 local_a1c;
  undefined4 local_a18;
  CHAR local_924 [256];
  undefined1 local_824 [256];
  undefined1 local_724 [8];
  undefined4 local_71c;
  undefined4 local_718;
  undefined4 local_314;
  undefined4 local_310;
  CHAR local_30c [512];
  undefined1 local_10c [256];
  void *local_c;
  undefined1 *puStack_8;
  uint local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00620f92;
  local_c = ExceptionList;
  if ((-1 < param_3) && (param_3 < 5)) {
    ExceptionList = &local_c;
    pCVar5 = (LPSTR)FUN_005e5c50(local_824,0xfffffffc);
    pCVar5 = CharUpperA(pCVar5);
    lstrcpyA(local_c4c,pCVar5);
    iVar6 = lstrcmpA(local_c4c,&DAT_00665958);
    if (iVar6 == 0) {
      if ((DAT_00674808 & 1) == 0) {
        DAT_00674808 = DAT_00674808 | 1;
        _DAT_00674b40 = 0;
        _DAT_00674b44 = 0;
        FUN_00605ff0(&DAT_005c0d40);
      }
      local_c3c = 0;
      local_b34 = 0;
      local_b30 = 0;
      local_b2c = 0;
      FUN_005ec020(param_2);
      local_4 = 0;
      if (param_6 == -1) {
        param_6 = *(int *)(param_1 + 0x364 + param_3 * 8);
      }
      iVar6 = param_6;
      local_71c = 1;
      local_718 = 0;
      local_314 = 0;
      iVar7 = FUN_005f7750(local_b30,local_724);
      if (iVar7 == 0) {
        iVar7 = param_6 * 0x94;
        local_c58 = param_6;
        do {
          local_c58 = local_c58 + 1;
          iVar8 = FUN_005f7810();
          if (iVar8 != 0) break;
          if (param_6 < *(int *)(param_1 + 0x364 + param_3 * 8)) {
            FUN_005c0ea0(param_3,param_6);
          }
          else {
            piVar2 = (int *)(param_1 + 0x360 + param_3 * 8);
            iVar8 = *(int *)(param_1 + 0x364 + param_3 * 8);
            while (local_c58 < iVar8) {
              piVar2[1] = iVar8 + -1;
              if (*piVar2 + (iVar8 + -1) * 0x94 != 0) {
                FUN_005c3320(1);
              }
              iVar8 = piVar2[1];
            }
            FUN_005bbf10(piVar2,iVar7 + 0x94);
            iVar8 = piVar2[1];
            piVar2[1] = iVar8;
            while (iVar8 < local_c58) {
              if (*piVar2 + piVar2[1] * 0x94 != 0) {
                FUN_005c32f0();
              }
              piVar2[1] = piVar2[1] + 1;
              iVar8 = piVar2[1];
            }
          }
          *(ushort *)(iVar7 + 0x90 + *(int *)(param_1 + 0x360 + param_3 * 8)) = param_4;
          *(undefined2 *)(iVar7 + 0x92 + *(int *)(param_1 + 0x360 + param_3 * 8)) = param_5;
          pvVar9 = operator_new(0x4c);
          local_4._0_1_ = 1;
          if (pvVar9 == (void *)0x0) {
            iVar8 = 0;
          }
          else {
            iVar8 = FUN_005c9210();
          }
          local_4 = (uint)local_4._1_3_ << 8;
          if (iVar8 == 0) {
            local_b28 = 0xffff0002;
            lstrcpyA(local_b24,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
            _CxxThrowException(&local_b28,(ThrowInfo *)&DAT_0063ac98);
          }
          iVar3 = *(int *)(param_1 + 0x360 + param_3 * 8);
          *(int *)(iVar7 + 0x80 + iVar3) = iVar8;
          *(undefined4 *)(iVar7 + 0x84 + iVar3) = 1;
          cVar4 = FUN_005ca910(&DAT_00674b40,local_724,0,0xffffffff);
          param_6 = param_6 + 1;
          iVar7 = iVar7 + 0x94;
        } while (cVar4 != '\0');
      }
      _DAT_00674b40 = 0;
      _DAT_00674b44 = 0;
      if ((param_4 & 0x40) != 0) {
        lpString2 = (LPCSTR)FUN_005e5d80(local_10c,4);
        lstrcpyA(local_924,lpString2);
        lpString2_00 = s__ALPHA_GIF_0066594c;
        iVar7 = lstrlenA(local_924);
        lstrcpyA(local_924 + iVar7,lpString2_00);
        FUN_0051fd00(local_924);
        local_b28 = local_b28 & 0xffffff00;
        local_a20 = 0;
        local_a1c = 0;
        local_a18 = 0;
        FUN_005ec020(local_824);
        local_4 = CONCAT31(local_4._1_3_,2);
        local_71c = 0;
        local_718 = 0;
        local_314 = 0;
        iVar7 = FUN_005f7750(local_a1c,local_724);
        if (iVar7 == 0) {
          iVar6 = iVar6 * 0x94;
          do {
            iVar7 = FUN_005f7810();
            if (iVar7 != 0) break;
            pvVar9 = operator_new(0x4c);
            local_4._0_1_ = 3;
            if (pvVar9 == (void *)0x0) {
              iVar7 = 0;
            }
            else {
              iVar7 = FUN_005c9210();
            }
            local_4 = CONCAT31(local_4._1_3_,2);
            if (iVar7 == 0) {
              local_310 = 0xffff0002;
              lstrcpyA(local_30c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
              _CxxThrowException(&local_310,(ThrowInfo *)&DAT_0063ac98);
            }
            iVar8 = *(int *)(param_1 + 0x360 + param_3 * 8);
            *(int *)(iVar6 + 0x88 + iVar8) = iVar7;
            *(undefined4 *)(iVar6 + 0x8c + iVar8) = 1;
            cVar4 = FUN_005ca910(&DAT_00674b40,local_724,0,0xffffffff);
            iVar6 = iVar6 + 0x94;
          } while (cVar4 != '\0');
        }
        _DAT_00674b40 = 0;
        _DAT_00674b44 = 0;
        local_4 = local_4 & 0xffffff00;
        FUN_005ec0e0();
      }
      local_4 = 0xffffffff;
      FUN_005ec0e0();
    }
    else {
      if (param_6 == -1) {
        param_6 = *(int *)(param_1 + 0x364 + param_3 * 8);
      }
      if (param_6 < *(int *)(param_1 + 0x364 + param_3 * 8)) {
        FUN_005c0ea0(param_3,param_6);
      }
      else {
        piVar2 = (int *)(param_1 + 0x360 + param_3 * 8);
        iVar7 = param_6 + 1;
        iVar6 = *(int *)(param_1 + 0x364 + param_3 * 8);
        while (iVar7 < iVar6) {
          piVar2[1] = iVar6 + -1;
          if (*piVar2 + (iVar6 + -1) * 0x94 != 0) {
            FUN_005c3320(1);
          }
          iVar6 = piVar2[1];
        }
        FUN_005bbf10(piVar2,iVar7 * 0x94);
        iVar6 = piVar2[1];
        piVar2[1] = iVar6;
        while (iVar6 < iVar7) {
          puVar1 = (undefined1 *)(*piVar2 + piVar2[1] * 0x94);
          if (puVar1 != (undefined1 *)0x0) {
            *puVar1 = 0;
            *(undefined4 *)(puVar1 + 0x80) = 0;
            *(undefined4 *)(puVar1 + 0x84) = 1;
            *(undefined4 *)(puVar1 + 0x88) = 0;
            *(undefined4 *)(puVar1 + 0x8c) = 1;
          }
          iVar6 = piVar2[1] + 1;
          piVar2[1] = iVar6;
        }
      }
      param_6 = param_6 * 0x94;
      lstrcpyA((LPSTR)(*(int *)(param_1 + 0x360 + param_3 * 8) + param_6),param_2);
      *(ushort *)(*(int *)(param_1 + 0x360 + param_3 * 8) + 0x90 + param_6) = param_4;
      *(undefined2 *)(*(int *)(param_1 + 0x360 + param_3 * 8) + 0x92 + param_6) = param_5;
      iVar6 = lstrcmpA(local_c4c,&DAT_00665944);
      if ((iVar6 == 0) || (iVar6 = lstrcmpA(local_c4c,&DAT_0066593c), iVar6 == 0)) {
        FUN_005c0fd0(param_3);
      }
    }
  }
  ExceptionList = local_c;
  return;
}


