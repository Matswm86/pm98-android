// FUN_004580b0  entry=004580b0  size=1646 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __thiscall
FUN_004580b0(void *this,char *param_1,uint param_2,ushort param_3,undefined2 param_4,int param_5)

{
  undefined1 *puVar1;
  int *piVar2;
  int iVar3;
  LPSTR pCVar4;
  int iVar5;
  int iVar6;
  int iVar7;
  undefined4 *puVar8;
  char *lpString2;
  int local_c58;
  CHAR local_c4c [16];
  undefined1 local_c3c [264];
  undefined4 local_b34;
  uint *local_b30;
  undefined4 local_b2c;
  uint local_b28;
  CHAR local_b24 [260];
  undefined4 local_a20;
  uint *local_a1c;
  undefined4 local_a18;
  CHAR local_924 [256];
  CHAR local_824 [256];
  uint local_724 [2];
  undefined4 local_71c;
  undefined4 local_718;
  undefined4 local_314;
  undefined4 local_310;
  CHAR local_30c [512];
  CHAR local_10c [256];
  void *local_c;
  undefined1 *puStack_8;
  uint local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00482bb2;
  local_c = ExceptionList;
  if ((-1 < (int)param_2) && ((int)param_2 < 5)) {
    ExceptionList = &local_c;
    pCVar4 = FUN_004658a0(param_1,local_824,0xfffffffc);
    pCVar4 = CharUpperA(pCVar4);
    lstrcpyA(local_c4c,pCVar4);
    iVar5 = lstrcmpA(local_c4c,&DAT_004958f4);
    if (iVar5 == 0) {
      if ((DAT_00501790 & 1) == 0) {
        DAT_00501790 = DAT_00501790 | 1;
        _DAT_00501c88 = 0;
        _DAT_00501c8c = 0;
        FUN_0047e000((_onexit_t)&DAT_00458720);
      }
      local_c3c[0] = 0;
      local_b34 = 0;
      local_b30 = (uint *)0x0;
      local_b2c = 0;
      FUN_00450f50(local_c3c,param_1);
      local_4 = 0;
      if (param_5 == -1) {
        param_5 = *(int *)((int)this + param_2 * 8 + 0x364);
      }
      iVar5 = param_5;
      local_71c = 1;
      local_718 = 0;
      local_314 = 0;
      iVar6 = FUN_0046b650(&DAT_00501c88,local_b30,local_724);
      if (iVar6 == 0) {
        iVar6 = param_5 * 0x94;
        local_c58 = param_5;
        do {
          local_c58 = local_c58 + 1;
          iVar7 = FUN_0046b710((int *)&DAT_00501c88);
          if (iVar7 != 0) break;
          if (param_5 < *(int *)((int)this + param_2 * 8 + 0x364)) {
            FUN_00458880(this,param_2,param_5);
          }
          else {
            piVar2 = (int *)((int)this + param_2 * 8 + 0x360);
            iVar7 = *(int *)((int)this + param_2 * 8 + 0x364);
            while (local_c58 < iVar7) {
              piVar2[1] = iVar7 + -1;
              iVar7 = *piVar2 + (iVar7 + -1) * 0x94;
              if (iVar7 != 0) {
                FUN_0045ad20(iVar7);
              }
              iVar7 = piVar2[1];
            }
            FUN_0044fb30(piVar2,iVar6 + 0x94);
            iVar7 = piVar2[1];
            piVar2[1] = iVar7;
            while (iVar7 < local_c58) {
              puVar1 = (undefined1 *)(*piVar2 + piVar2[1] * 0x94);
              if (puVar1 != (undefined1 *)0x0) {
                FUN_0045acc0(puVar1);
              }
              piVar2[1] = piVar2[1] + 1;
              iVar7 = piVar2[1];
            }
          }
          *(ushort *)(iVar6 + 0x90 + *(int *)((int)this + param_2 * 8 + 0x360)) = param_3;
          *(undefined2 *)(iVar6 + 0x92 + *(int *)((int)this + param_2 * 8 + 0x360)) = param_4;
          puVar8 = operator_new(0x4c);
          local_4._0_1_ = 1;
          if (puVar8 == (undefined4 *)0x0) {
            iVar7 = 0;
          }
          else {
            iVar7 = FUN_0044c790(puVar8);
          }
          local_4 = (uint)local_4._1_3_ << 8;
          if (iVar7 == 0) {
            local_b28 = 0xffff0002;
            lstrcpyA(local_b24,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
            _CxxThrowException(&local_b28,(ThrowInfo *)&DAT_0048b400);
          }
          iVar3 = *(int *)((int)this + param_2 * 8 + 0x360);
          *(int *)(iVar6 + 0x80 + iVar3) = iVar7;
          *(undefined4 *)(iVar6 + 0x84 + iVar3) = 1;
          iVar7 = FUN_0044dea0(*(void **)(iVar6 + 0x80 + *(int *)((int)this + param_2 * 8 + 0x360)),
                               &DAT_00501c88,local_724,0,-1);
          param_5 = param_5 + 1;
          iVar6 = iVar6 + 0x94;
        } while ((char)iVar7 != '\0');
      }
      _DAT_00501c88 = 0;
      _DAT_00501c8c = 0;
      if ((param_3 & 0x40) != 0) {
        pCVar4 = FUN_00465930(param_1,local_10c,4);
        lstrcpyA(local_924,pCVar4);
        lpString2 = s__ALPHA_GIF_00495a04;
        iVar6 = lstrlenA(local_924);
        lstrcpyA(local_924 + iVar6,lpString2);
        FUN_0040d1f0(local_824,local_924);
        local_b28 = local_b28 & 0xffffff00;
        local_a20 = 0;
        local_a1c = (uint *)0x0;
        local_a18 = 0;
        FUN_00450f50(&local_b28,local_824);
        local_4 = CONCAT31(local_4._1_3_,2);
        local_71c = 0;
        local_718 = 0;
        local_314 = 0;
        iVar6 = FUN_0046b650(&DAT_00501c88,local_a1c,local_724);
        if (iVar6 == 0) {
          iVar5 = iVar5 * 0x94;
          do {
            iVar6 = FUN_0046b710((int *)&DAT_00501c88);
            if (iVar6 != 0) break;
            puVar8 = operator_new(0x4c);
            local_4._0_1_ = 3;
            if (puVar8 == (undefined4 *)0x0) {
              iVar6 = 0;
            }
            else {
              iVar6 = FUN_0044c790(puVar8);
            }
            local_4 = CONCAT31(local_4._1_3_,2);
            if (iVar6 == 0) {
              local_310 = 0xffff0002;
              lstrcpyA(local_30c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
              _CxxThrowException(&local_310,(ThrowInfo *)&DAT_0048b400);
            }
            iVar7 = *(int *)((int)this + param_2 * 8 + 0x360);
            *(int *)(iVar5 + 0x88 + iVar7) = iVar6;
            *(undefined4 *)(iVar5 + 0x8c + iVar7) = 1;
            iVar6 = FUN_0044dea0(*(void **)(iVar5 + 0x88 + *(int *)((int)this + param_2 * 8 + 0x360)
                                           ),&DAT_00501c88,local_724,0,-1);
            iVar5 = iVar5 + 0x94;
          } while ((char)iVar6 != '\0');
        }
        _DAT_00501c88 = 0;
        _DAT_00501c8c = 0;
        local_4 = local_4 & 0xffffff00;
        FUN_00451010((undefined1 *)&local_b28);
      }
      local_4 = 0xffffffff;
      FUN_00451010(local_c3c);
    }
    else {
      if (param_5 == -1) {
        param_5 = *(int *)((int)this + param_2 * 8 + 0x364);
      }
      if (param_5 < *(int *)((int)this + param_2 * 8 + 0x364)) {
        FUN_00458880(this,param_2,param_5);
      }
      else {
        piVar2 = (int *)((int)this + param_2 * 8 + 0x360);
        iVar6 = param_5 + 1;
        iVar5 = *(int *)((int)this + param_2 * 8 + 0x364);
        while (iVar6 < iVar5) {
          piVar2[1] = iVar5 + -1;
          iVar5 = *piVar2 + (iVar5 + -1) * 0x94;
          if (iVar5 != 0) {
            FUN_0045ad20(iVar5);
          }
          iVar5 = piVar2[1];
        }
        FUN_0044fb30(piVar2,iVar6 * 0x94);
        iVar5 = piVar2[1];
        piVar2[1] = iVar5;
        while (iVar5 < iVar6) {
          puVar1 = (undefined1 *)(*piVar2 + piVar2[1] * 0x94);
          if (puVar1 != (undefined1 *)0x0) {
            *puVar1 = 0;
            *(undefined4 *)(puVar1 + 0x80) = 0;
            *(undefined4 *)(puVar1 + 0x84) = 1;
            *(undefined4 *)(puVar1 + 0x88) = 0;
            *(undefined4 *)(puVar1 + 0x8c) = 1;
          }
          iVar5 = piVar2[1] + 1;
          piVar2[1] = iVar5;
        }
      }
      iVar5 = param_5 * 0x94;
      lstrcpyA((LPSTR)(*(int *)((int)this + param_2 * 8 + 0x360) + iVar5),param_1);
      *(ushort *)(*(int *)((int)this + param_2 * 8 + 0x360) + 0x90 + iVar5) = param_3;
      *(undefined2 *)(*(int *)((int)this + param_2 * 8 + 0x360) + 0x92 + iVar5) = param_4;
      iVar5 = lstrcmpA(local_c4c,&DAT_004958dc);
      if ((iVar5 == 0) || (iVar5 = lstrcmpA(local_c4c,&DAT_004958e4), iVar5 == 0)) {
        FUN_004589b0(this,param_2);
      }
    }
  }
  ExceptionList = local_c;
  return;
}


