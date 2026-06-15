// FUN_0046fe70  entry=0046fe70  size=476 bytes
// callers/callees expanded one level from seeds

undefined4 __thiscall FUN_0046fe70(int param_1,undefined4 param_2)

{
  int iVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined4 extraout_ECX_01;
  undefined4 uVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined1 *puVar8;
  undefined4 uStack_44;
  undefined1 *puStack_40;
  undefined4 uStack_3c;
  char *local_38;
  undefined1 local_28 [40];
  
  local_38 = (char *)0x0;
  uStack_3c = 0x46fe89;
  FUN_00436270();
  local_38 = (char *)0x0;
  uStack_3c = 0;
  puStack_40 = &DAT_00666f70;
  uStack_44 = 0x35;
  uStack_44 = FUN_00436fb0(0xc9);
  uStack_44 = FUN_00436fd0(&stack0x00000008);
  iVar1 = FUN_005bc780(param_2);
  if (iVar1 == 0) {
    return 0;
  }
  local_38 = s_Proman10_00652e9c;
  uStack_3c = 0x46fed7;
  FUN_005beae0();
  puStack_40 = (undefined1 *)0xffffff;
  local_38 = (char *)0x0;
  iVar1 = *(int *)(param_1 + 0x3f4);
  uStack_44 = 0x46fef5;
  FUN_00436270();
  puStack_40 = (undefined1 *)0x0;
  uStack_44 = 0;
  puVar8 = &DAT_00666f70;
  uVar2 = FUN_00436fb0(0xc5,0xd);
  uVar3 = FUN_00436fb0(2,2);
  uVar2 = FUN_00436fd0(uVar3,uVar2);
  (**(code **)(iVar1 + 0xc0))(param_1,uVar2,puVar8);
  uVar7 = 0xffffff;
  iVar1 = *(int *)(param_1 + 0x1430);
  uVar2 = extraout_ECX;
  FUN_00436270(0);
  uVar6 = 0;
  uVar5 = 0;
  puVar8 = &DAT_00666f70;
  uVar3 = FUN_00436fb0(0xc5,0x24);
  uVar4 = FUN_00436fb0(2,0xf);
  uVar3 = FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar1 + 0xc0))(param_1,uVar3,puVar8,uVar5,uVar6,uVar2,uVar7);
  uVar7 = 0xffffffff;
  iVar1 = *(int *)(param_1 + 0x80c);
  uVar2 = extraout_ECX_00;
  FUN_004ac740(local_28);
  uVar6 = 0;
  uVar5 = 0x820;
  puVar8 = &DAT_00666f70;
  uVar3 = FUN_00436fb0(0xa1,0xf);
  uVar4 = FUN_00436fb0(0x27,0x11);
  uVar3 = FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar1 + 0xc0))(param_1,uVar3,puVar8,uVar5,uVar6,uVar2,uVar7);
  uVar7 = 0xffffffff;
  iVar1 = *(int *)(param_1 + 0xc24);
  uVar2 = extraout_ECX_01;
  FUN_004ac740(&uStack_44);
  uVar6 = 0;
  uVar5 = 0x820;
  puVar8 = &DAT_00666f70;
  uVar3 = FUN_00436fb0(0xa1,0xf);
  uVar4 = FUN_00436fb0(0x27,0x1e);
  uVar3 = FUN_00436fd0(uVar4,uVar3);
  (**(code **)(iVar1 + 0xc0))(param_1,uVar3,puVar8,uVar5,uVar6,uVar2,uVar7);
  return 1;
}


