// FUN_00480990  entry=00480990  size=484 bytes
// callers/callees expanded one level from seeds

bool __thiscall
FUN_00480990(int *param_1,int param_2,int param_3,undefined2 param_4,undefined2 param_5)

{
  undefined4 *puVar1;
  undefined4 uVar2;
  int iVar3;
  char *pcVar4;
  undefined4 uVar5;
  CRect local_220 [16];
  undefined4 local_210;
  CHAR local_20c [512];
  void *pvStack_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0060d369;
  pvStack_c = ExceptionList;
  ExceptionList = &pvStack_c;
  param_1[3] = param_3;
  *(undefined2 *)(param_1 + 2) = param_5;
  puVar1 = operator_new(0xc54);
  local_4 = 0;
  if (puVar1 == (undefined4 *)0x0) {
    puVar1 = (undefined4 *)0x0;
  }
  else {
    FUN_0043e8c0();
    *puVar1 = &PTR_LAB_00624d08;
    local_4._0_1_ = 1;
    FUN_0046b3f0();
    local_4 = CONCAT31(local_4._1_3_,2);
    FUN_005bc430();
    *puVar1 = &PTR_LAB_00628c48;
  }
  local_4 = 0xffffffff;
  if (puVar1 == (undefined4 *)0x0) {
    local_210 = 0xffff0002;
    lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  param_1[0x84e] = (int)puVar1;
  FUN_00436270();
  FUN_00436270();
  FUN_00437020(0x2a,0x5f,0xaa);
  uVar5 = 0;
  pcVar4 = s_PREMIER_LEAGUE_00652e34;
  uVar2 = CRect::CRect(local_220,0x56,0x54,0x1a9,0x6f);
  FUN_00466670(param_2,uVar2,pcVar4,uVar5);
  FUN_005beae0();
  FUN_005c5d30();
  (**(code **)(*(int *)param_1[3] + 0x158))();
  iVar3 = FUN_00467c30(param_2);
  if (iVar3 != 0) {
    param_1[0x84f] = param_2;
    *(undefined2 *)(param_1 + 0x850) = param_4;
    (**(code **)(*(int *)param_1[3] + 0x164))();
    param_1[1] = 0;
    (**(code **)(*param_1 + 0x14))();
  }
  ExceptionList = pvStack_c;
  return iVar3 != 0;
}


