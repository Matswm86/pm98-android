// FUN_005cbea0  entry=005cbea0  size=486 bytes

undefined1
FUN_005cbea0(uint param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
            undefined4 param_5,undefined4 param_6,undefined4 param_7,undefined1 *param_8,
            undefined1 *param_9,undefined4 param_10,undefined4 param_11,uint param_12)

{
  uint uVar1;
  char cVar2;
  undefined1 uVar3;
  uint uVar4;
  undefined1 *puVar5;
  undefined1 *puVar6;
  undefined1 local_a4 [76];
  undefined1 local_58 [76];
  void *local_c;
  undefined1 *puStack_8;
  uint local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00621473;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005c9210();
  local_4 = 0;
  FUN_005c9210();
  puVar5 = param_9;
  local_4 = CONCAT31(local_4._1_3_,1);
  puVar6 = param_8;
  if ((param_1 & 3) != 0) {
    FUN_005d6820(param_8,param_1 & 3);
    puVar6 = local_58;
  }
  uVar1 = param_12;
  if ((param_1 & 0x20) == 0) {
    if ((param_1 & 0x10) != 0) {
      if ((char)param_2 == '\0') {
        uVar4 = param_12 & 0xffff;
      }
      else {
        uVar4 = 0x100;
      }
      FUN_005d66f0(puVar6,uVar4);
      goto LAB_005cbf84;
    }
  }
  else {
    if ((char)param_2 == '\0') {
      uVar4 = param_12 & 0xffff;
    }
    else {
      uVar4 = 0x100;
    }
    cVar2 = FUN_005d66f0(puVar6,0x100);
    if (cVar2 != '\0') {
      FUN_005d60a0(uVar4);
    }
LAB_005cbf84:
    puVar5 = local_a4;
  }
  if ((char)param_2 == '\0') {
LAB_005cbfaf:
    if (puVar5 != (undefined1 *)0x0) {
      uVar3 = FUN_005d5220(&param_4,puVar5,&param_10,puVar6,&param_10);
      goto LAB_005cc042;
    }
  }
  else if (puVar5 != (undefined1 *)0x0) {
    FUN_005d6590(puVar5,param_2,param_3,uVar1);
    puVar5 = local_a4;
    goto LAB_005cbfaf;
  }
  if ((ushort)uVar1 < 0x100) {
    uVar3 = FUN_005d5540(&param_4,uVar1,puVar6,&param_10);
  }
  else {
    uVar3 = FUN_005cba50(param_4,param_5,param_6,param_7,puVar6,param_10,param_11);
  }
LAB_005cc042:
  local_4 = local_4 & 0xffffff00;
  thunk_FUN_005cb040();
  local_4 = 0xffffffff;
  thunk_FUN_005cb040();
  ExceptionList = local_c;
  return uVar3;
}


