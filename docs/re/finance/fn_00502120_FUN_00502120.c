// FUN_00502120  entry=00502120  size=298 bytes

void __fastcall FUN_00502120(int param_1)

{
  int iVar1;
  undefined4 *puVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined1 *puVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined4 local_210;
  CHAR local_20c [484];
  void *pvStack_28;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0061704d;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  puVar2 = operator_new(0x3f4);
  local_4 = 0;
  if (puVar2 == (undefined4 *)0x0) {
    puVar2 = (undefined4 *)0x0;
  }
  else {
    FUN_005bc430();
    *puVar2 = &PTR_LAB_0062dc88;
  }
  local_4 = 0xffffffff;
  if (puVar2 == (undefined4 *)0x0) {
    local_210 = 0xffff0002;
    lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  *(undefined4 **)(param_1 + 0x3ed4) = puVar2;
  iVar1 = **(int **)(param_1 + 0x3ed4);
  FUN_00436270(0xffffffff);
  uVar7 = 0;
  uVar6 = 0;
  puVar5 = &DAT_00666f70;
  uVar3 = FUN_00436fb0(0x250,0x143);
  uVar4 = FUN_00436fb0(0x15,0x4e);
  uVar3 = FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar1 + 0xc0))(param_1,uVar3,puVar5,uVar6,uVar7);
  FUN_005beae0(s_Proman10_00652e9c);
  FUN_005c5d30(*(undefined4 *)(param_1 + 0x3ed4),1);
  ExceptionList = pvStack_28;
  return;
}


