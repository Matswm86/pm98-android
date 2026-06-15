// FUN_0048ff10  entry=0048ff10  size=553 bytes
// callers/callees expanded one level from seeds

undefined4 __thiscall
FUN_0048ff10(uint param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,uint param_5,
            uint param_6,int param_7,int param_8,uint *param_9)

{
  uint uVar1;
  uint uVar2;
  char cVar3;
  undefined4 uVar4;
  int iVar5;
  undefined1 *puVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  uint uStack_7c;
  undefined1 local_58 [76];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0060ee88;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *(uint **)(param_1 + 0x3f4) = param_9;
  param_9 = &uStack_7c;
  uStack_7c = param_1;
  FUN_00436270(0xffffffff);
  uVar8 = 0;
  uVar7 = 0;
  puVar6 = &DAT_00666f70;
  uVar4 = FUN_00436fb0(0x1ca,0x48);
  uVar4 = FUN_00436fd0(&param_3,uVar4);
  iVar5 = FUN_005bc780(param_2,uVar4,puVar6,uVar7,uVar8);
  uVar1 = param_5;
  if (iVar5 == 0) {
    ExceptionList = local_c;
    return 0;
  }
  uStack_7c = (uint)*(ushort *)(param_5 + 0x38);
  FUN_00585ee0();
  uStack_7c = 0x48ffca;
  uVar4 = FUN_005796f0();
  *(undefined4 *)(param_1 + 0x3f8) = uVar4;
  uStack_7c = (uint)*(ushort *)(uVar1 + 0x3a);
  FUN_00585ee0();
  uStack_7c = 0x48ffe8;
  uVar4 = FUN_005796f0();
  *(undefined4 *)(param_1 + 0x3fc) = uVar4;
  uStack_7c = 0x48fff7;
  FUN_005c9210();
  uStack_7c = 0x100;
  local_4 = 0;
  cVar3 = FUN_005d66f0(*(undefined4 *)(param_1 + 0x3f8));
  if (cVar3 != '\0') {
    uStack_7c = 0x100;
    FUN_005d60a0();
  }
  uStack_7c = 0x100;
  FUN_005d6590(local_58,0x20,0x80);
  uStack_7c = 0x100;
  cVar3 = FUN_005d66f0(*(undefined4 *)(param_1 + 0x3fc));
  if (cVar3 != '\0') {
    uStack_7c = 0x100;
    FUN_005d60a0();
  }
  uStack_7c = 0x100;
  FUN_005d6590(local_58,0x20,0x80);
  uStack_7c = 0xffffffff;
  FUN_005c9f60(s_img_resultados_uefa_gana_izquier_0065449c,0);
  uStack_7c = 0xffffffff;
  FUN_005c9f60(s_img_resultados_uefa_gana_derecha_00654474,0);
  uStack_7c = 0xffffffff;
  FUN_005c9f60(s_img_resultados_uefa_flecha_cuart_0065444c,0);
  uStack_7c = uVar1;
  FUN_00448530();
  uVar2 = param_6;
  if (param_7 == 0) {
    uVar4 = 0;
  }
  else {
    uVar4 = *(undefined4 *)(uVar1 + 0x40);
  }
  *(undefined4 *)(param_1 + 0x5bc) = uVar4;
  uStack_7c = param_6;
  FUN_00448530();
  if (param_8 == 0) {
    uVar4 = 0;
  }
  else {
    uVar4 = *(undefined4 *)(uVar2 + 0x40);
  }
  *(undefined4 *)(param_1 + 0x678) = uVar4;
  local_4 = 0xffffffff;
  uStack_7c = 0x490121;
  thunk_FUN_005cb040();
  ExceptionList = local_c;
  return 1;
}


