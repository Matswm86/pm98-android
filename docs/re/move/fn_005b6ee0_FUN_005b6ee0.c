// FUN_005b6ee0  entry=005b6ee0  size=409 bytes

void __fastcall FUN_005b6ee0(int param_1)

{
  undefined2 *puVar1;
  undefined2 *puVar2;
  undefined2 *puVar3;
  int iVar4;
  int iVar5;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  undefined2 extraout_var_01;
  int iVar6;
  undefined2 extraout_var_02;
  undefined2 extraout_var_03;
  undefined2 extraout_var_04;
  undefined4 uVar7;
  
  iVar4 = *(int *)(*(int *)(param_1 + 0x138) + 0x468);
  iVar5 = *(int *)(param_1 + 8);
  if (iVar5 == 0) {
    iVar6 = *(int *)(iVar4 + 0xfa8);
  }
  else {
    iVar6 = *(int *)(iVar4 + 0xfac);
  }
  if (iVar6 == 1) {
    uVar7 = 2;
  }
  else {
    if (iVar5 == 0) {
      iVar6 = *(int *)(iVar4 + 0xfa8);
    }
    else {
      iVar6 = *(int *)(iVar4 + 0xfac);
    }
    if (iVar6 != 2) {
      puVar1 = (undefined2 *)(param_1 + 0x2fa);
      puVar2 = (undefined2 *)(param_1 + 0x2f8);
      puVar3 = (undefined2 *)(param_1 + 0x2f0);
      if (iVar5 == 0) {
        *(undefined2 *)(param_1 + 0x2f2) = *(undefined2 *)(iVar4 + 0xfb0);
        *(undefined2 *)(param_1 + 0x2f6) = *(undefined2 *)(iVar4 + 0xfb2);
        *(undefined2 *)(param_1 + 0x2f4) = *(undefined2 *)(iVar4 + 0xfb4);
        *puVar3 = *(undefined2 *)(iVar4 + 0xfb6);
        *puVar2 = *(undefined2 *)(iVar4 + 0xfb8);
        *puVar1 = *(undefined2 *)(iVar4 + 0xfba);
      }
      else {
        FUN_004b8110((undefined2 *)(param_1 + 0x2f2),param_1 + 0x2f6,param_1 + 0x2f4,puVar3,puVar2,
                     puVar1);
      }
      FUN_005f5600(1);
      FUN_005f5520(2,CONCAT22(extraout_var_02,*puVar3));
      FUN_005f5520(3,CONCAT22(extraout_var,*(undefined2 *)(param_1 + 0x2f2)));
      FUN_005f5520(1,CONCAT22(extraout_var_03,*(undefined2 *)(param_1 + 0x2f4)));
      FUN_005f5520(4,CONCAT22(extraout_var_00,*(undefined2 *)(param_1 + 0x2f6)));
      FUN_005f5520(6,CONCAT22(extraout_var_04,*puVar2));
      FUN_005f5520(5,CONCAT22(extraout_var_01,*puVar1));
      return;
    }
    uVar7 = 3;
  }
  FUN_005f5600(uVar7);
  return;
}


